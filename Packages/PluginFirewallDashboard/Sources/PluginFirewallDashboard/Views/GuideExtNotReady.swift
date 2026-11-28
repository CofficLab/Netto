import LumiUI
import ProviderFirewall
import ProviderViewEnvironment
import SwiftUI

public struct ExtensionNotReady: View {
    public init() {}

    public var body: some View {
        DashboardGuidePanel(
            iconName: "exclamationmark.shield",
            title: "Activate System Extension",
            iconColor: .orange
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                DashboardGuideSteps("Activation Steps", steps: [
                    "Open System Settings",
                    "Find this app's extension (if there is no entry, reinstall it below)",
                    "Turn the switch on",
                ])

                VStack(spacing: AppUI.Spacing.sm) {
                    DashboardOpenSystemSettingsButton()
                    // 扩展未注册时系统设置里不会有条目，提供重新注册入口避免死循环。
                    DashboardInstallExtensionButton(
                        title: String(localized: "Reinstall Extension"),
                        busyTitle: String(localized: "Submitting…"),
                        style: .secondary
                    )
                }
            }
        }
    }
}

#Preview {
    ExtensionNotReady()
        .dashboardPreviewRoot()
        .frame(height: 500)
}

#Preview("App") {
    DashboardPreviewHost {
        ContentView()
    }
    .frame(height: 800)
}
