import LumiUI
import SwiftUI

struct FilterNotInstalledView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "exclamationmark.triangle",
            title: "Filter Not Installed",
            iconColor: .red
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                Text("The network filter is not installed, so the firewall cannot start")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                DashboardGuideSteps("Solution", steps: [
                    "Click the button below to install the filter",
                    "Wait for the filter installation to finish",
                ])

                BtnInstallFilter()
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Large") {
    DashboardPreviewHost {
        FilterNotInstalledView()
    }
    .frame(width: 600, height: 1000)
}

#Preview("App - Small") {
    DashboardPreviewHost {
        FilterNotInstalledView()
    }
    .frame(width: 600, height: 600)
}
