import LumiUI
import SwiftUI

struct FilterNotInstalledView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "exclamationmark.triangle",
            title: "过滤器未安装",
            iconColor: .red
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                Text("网络过滤器未安装，无法启动防火墙功能")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                DashboardGuideSteps("解决方案", steps: [
                    "点击下方按钮安装过滤器",
                    "等待过滤器安装完成",
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
