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
            title: "Firewall Not Active",
            iconColor: .orange
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                Text("The filter is not responding. Network traffic may not be blocked.")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Repairing recreates the filter configuration. If that does not help, restart Netpause or your Mac.")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let errorMessage {
                    AppStatusBanner(kind: .error, title: "Repair Failed", message: errorMessage)
                }

                AppButton(
                    isBusy ? String(localized: "Repairing…") : String(localized: "Repair Filter"),
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