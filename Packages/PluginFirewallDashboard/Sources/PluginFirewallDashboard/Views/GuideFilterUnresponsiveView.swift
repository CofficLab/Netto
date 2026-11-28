import LumiUI
import ProviderViewEnvironment
import ProviderFirewall
import SwiftUI

/// 过滤器未响应：系统配置里过滤器是启用的，但扩展长时间没有心跳。
///
/// 典型场景是 Dev / TestFlight 构建切换后，旧过滤器配置仍绑定着上一次
/// 安装的签名，系统拒绝启动扩展 —— 界面显示「运行中」，实际没有任何拦截。
struct FilterUnresponsiveView: View {
    @Environment(\.firewallProvider) private var firewall: FirewallProviding?

    @State private var isBusy = false
    @State private var errorMessage: String?

    var body: some View {
        DashboardGuidePanel(
            iconName: "exclamationmark.shield.fill",
            title: "防火墙未生效",
            iconColor: .orange
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                Text("过滤器没有响应，网络流量可能没有被拦截。")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("修复后会重新创建过滤器配置；如果仍然无效，请重启 Netpause 或电脑。")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let errorMessage {
                    AppStatusBanner(kind: .error, title: "修复失败", message: errorMessage)
                }

                AppButton(
                    isBusy ? "修复中…" : "修复过滤器",
                    systemImage: "wrench.and.screwdriver",
                    style: .primary,
                    fillsWidth: true,
                    action: repair
                )
                .disabled(isBusy || firewall == nil)
                .frame(width: 150)
                .frame(height: 50)
                .accessibilityIdentifier("netpause.firewall.repair")
            }
        }
    }

    private func repair() {
        guard let firewall, !isBusy else { return }
        isBusy = true
        errorMessage = nil
        Task {
            do {
                try await firewall.repairFilter()
            } catch {
                errorMessage = error.localizedDescription
            }
            isBusy = false
        }
    }
}

#Preview {
    DashboardPreviewHost {
        FilterUnresponsiveView()
    }
    .frame(width: 600, height: 700)
}