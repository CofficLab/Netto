import LumiUI
import SwiftUI

/// 系统扩展安装进行中：只展示进度，操作与状态由弹窗头部承载。
struct InstallingView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "gearshape.arrow.triangle.2.circlepath",
            title: "正在安装系统扩展",
            iconColor: .orange
        ) {
            VStack(spacing: AppUI.Spacing.sm) {
                ProgressView()
                    .controlSize(.small)

                Text("请稍候，安装完成后这里会自动更新。")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    DashboardPreviewHost {
        InstallingView()
    }
    .frame(height: 500)
}
