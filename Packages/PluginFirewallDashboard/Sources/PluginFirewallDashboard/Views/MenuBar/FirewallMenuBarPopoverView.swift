import ProviderFirewall
import SwiftUI

/// 菜单栏弹出面板中由插件贡献的紧凑区块：当前状态 + 一键开启/停止。
///
/// 复杂界面（应用列表、事件详情）留在主窗口，这里只做状态与控制。
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: presentation.symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(presentation.color)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(presentation.title)
                        .font(.system(size: 12, weight: .medium))

                    Text(detailText)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                actionButton
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                    .lineLimit(2)
                    .padding(.leading, 32)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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
            Button("停止") { stop() }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isBusy || !snapshot.canStop)
                .accessibilityIdentifier("netto.menubar.firewall.stop")
        } else {
            Button("开启") { start() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
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
