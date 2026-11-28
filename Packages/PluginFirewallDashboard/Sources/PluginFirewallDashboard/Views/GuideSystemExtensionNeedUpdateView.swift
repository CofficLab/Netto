import LumiUI
import ProviderFirewall
import ProviderViewEnvironment
import SwiftUI

struct SystemExtensionNeedUpdateView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "arrow.clockwise.circle",
            title: "System Extension Update Required",
            iconColor: .orange
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                Text("An older version of the system extension is installed. Update it to the current version.")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                DashboardGuideSteps("Update Steps", steps: [
                    "Click the button below to update the system extension",
                    "The system replaces the old extension automatically",
                    "Wait for the update to finish, then the firewall will work",
                ])

                DashboardInstallExtensionButton()
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Large") {
    DashboardPreviewHost {
        SystemExtensionNeedUpdateView()
    }
    .frame(width: 600, height: 1000)
}

#Preview("App - Small") {
    DashboardPreviewHost {
        SystemExtensionNeedUpdateView()
    }
    .frame(width: 600, height: 600)
}
