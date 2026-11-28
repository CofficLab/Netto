import LumiUI
import ProviderViewEnvironment
import ProviderFirewall
import SwiftUI

/// App 与系统扩展的 IPC 连接中断：扩展侧在无 App 连接时会放行全部流量。
///
/// 典型原因是过滤器运行期间扩展被替换（App 升级），旧的 Mach service
/// 端点随之失效。重建过滤器配置无法恢复端点，需要重启 App/系统或重新
/// 启用扩展，因此这里只提供重新检测，不提供「修复」。
struct ExtensionConnectionLostView: View {
    @Environment(\.firewallProvider) private var firewall: FirewallProviding?

    @State private var isBusy = false

    var body: some View {
        DashboardGuidePanel(
            iconName: "bolt.horizontal.circle.fill",
            title: "Extension Connection Lost",
            iconColor: .orange
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                Text("Netpause can't communicate with its system extension. Firewall rules may not be applied until the connection is restored.")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Quit and reopen Netpause. If this keeps happening, restart your Mac or turn the Netpause extension off and on in System Settings › Login Items & Extensions › Network Extensions.")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                AppButton(
                    isBusy ? String(localized: "Checking…") : String(localized: "Check Again"),
                    systemImage: "arrow.clockwise",
                    style: .primary,
                    fillsWidth: true,
                    action: checkAgain
                )
                .disabled(isBusy || firewall == nil)
                .frame(width: 150)
                .frame(height: 50)
                .accessibilityIdentifier("netpause.firewall.reconnect")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("netpause.firewall.extensionConnectionLost")
    }

    private func checkAgain() {
        guard let firewall, !isBusy else { return }
        isBusy = true
        Task {
            await firewall.refresh()
            isBusy = false
        }
    }
}

#Preview {
    DashboardPreviewHost {
        ExtensionConnectionLostView()
    }
    .frame(width: 600, height: 700)
}