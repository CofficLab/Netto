import LumiUI
import ProviderFirewall
import ProviderViewEnvironment
import SwiftUI

struct SystemExtensionNotInstalledView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "exclamationmark.triangle",
            title: "System Extension Not Installed",
            iconColor: .red
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                Text("The system extension is not installed, so the firewall cannot start")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                DashboardGuideSteps("Solution", steps: [
                    "Click the button below to submit the installation request",
                    "Find this app's extension in System Settings",
                    "Turn on the extension switch and wait for installation to finish",
                ])

                DashboardInstallExtensionButton()
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Large") {
    DashboardPreviewHost {
        SystemExtensionNotInstalledView()
    }
    .frame(width: 600, height: 1000)
}

#Preview("App - Small") {
    DashboardPreviewHost {
        SystemExtensionNotInstalledView()
    }
    .frame(width: 600, height: 600)
}
