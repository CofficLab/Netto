import LumiUI
import SwiftUI

struct NotInApplicationsFolderView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "folder.badge.questionmark",
            title: "APP未安装在Applications目录",
            iconColor: .orange
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                Text("请将APP移动到Applications目录后再试")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                DashboardGuideSteps("操作步骤", steps: [
                    "退出当前软件",
                    "打开Finder",
                    "找到当前APP的位置",
                    "将APP拖拽到Applications文件夹",
                    "重新启动APP",
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
