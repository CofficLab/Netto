import LumiUI
import SwiftUI

struct NotInApplicationsFolderView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "folder.badge.questionmark",
            title: "需要移入应用程序文件夹",
            iconColor: .orange
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                Text("请将 App 移入 /Applications 后重试")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                DashboardGuideSteps("操作步骤", steps: [
                    "退出当前应用",
                    "打开 Finder",
                    "将 App 拖到 /Applications 文件夹",
                    "重新打开 App",
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
