import LumiUI
import ProviderFirewall
import SwiftUI

/// 菜单栏弹窗的主界面：防火墙状态与启停 + 筛选、应用列表与事件详情。
///
/// Attached 作为弹窗里唯一的插件贡献项；共享宿主只保留品牌信息与
/// 「设置 / 退出」菜单行。
struct FirewallMenuBarPopoverView: View {
    let firewall: any FirewallProviding
    let deniedApps: MenuBarDeniedAppsModel

    @State private var snapshot: FirewallSnapshot
    @State private var isBusy = false
    @State private var errorMessage: String?

    init(firewall: any FirewallProviding, deniedApps: MenuBarDeniedAppsModel) {
        self.firewall = firewall
        self.deniedApps = deniedApps
        _snapshot = State(initialValue: firewall.snapshot)
    }

    private var presentation: FirewallStatusPresentation {
        FirewallStatusPresentation(state: snapshot.state)
    }

    var body: some View {
        StatusBarPopoverScaffold(
            title: presentation.title,
            systemImage: presentation.symbol,
            systemImageColor: presentation.color,
            subtitle: detailText
        ) {
            actionButton
        } content: {
            if let errorMessage {
                AppStatusBanner(kind: .error, title: "操作失败", message: errorMessage)
                    .padding(.horizontal, 8)
            }

            ContentView()
        }
        // 水平内边距只作用于头部与筛选控件；应用列表在 ContentView 里抵消，
        // 与 Lumi 的菜单栏弹窗一样通栏。
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("netto.menubar.firewall")
        .task {
            deniedApps.start()
            for await update in firewall.observe() {
                snapshot = update
            }
        }
    }

    private var detailText: String {
        guard deniedApps.deniedCount > 0 else { return presentation.detail }
        return "已阻止 \(deniedApps.deniedCount) 个应用"
    }

    @ViewBuilder
    private var actionButton: some View {
        if snapshot.state.isRunning() {
            AppButton("停止", style: .secondary, size: .small, action: stop)
                .disabled(isBusy || !snapshot.canStop)
                .accessibilityIdentifier("netto.menubar.firewall.stop")
        } else {
            AppButton("开启", style: .primary, size: .small, action: start)
                .disabled(isBusy || !snapshot.canStart)
                .accessibilityIdentifier("netto.menubar.firewall.start")
        }
    }

    private func start() {
        isBusy = true
        errorMessage = nil
        Task {
            do {
                try await firewall.start()
            } catch {
                errorMessage = error.localizedDescription
            }
            isBusy = false
        }
    }

    private func stop() {
        isBusy = true
        errorMessage = nil
        Task {
            do {
                try await firewall.stop()
            } catch {
                errorMessage = error.localizedDescription
            }
            isBusy = false
        }
    }
}
