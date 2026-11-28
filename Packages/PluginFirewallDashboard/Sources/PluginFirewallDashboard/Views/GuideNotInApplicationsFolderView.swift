import LumiUI
import SwiftUI

struct NotInApplicationsFolderView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "folder.badge.questionmark",
            title: "Move to Applications Folder",
            iconColor: .orange
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                Text("Move the app to /Applications and try again")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                DashboardGuideSteps("Setup Steps", steps: [
                    "Quit the current app",
                    "Open Finder",
                    "Drag the app into the /Applications folder",
                    "Reopen the app",
                ])
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Large") {
    DashboardPreviewHost {
        NotInApplicationsFolderView()
    }
    .frame(width: 600, height: 1000)
}

#Preview("App - Small") {
    DashboardPreviewHost {
        NotInApplicationsFolderView()
    }
    .frame(width: 600, height: 600)
}
