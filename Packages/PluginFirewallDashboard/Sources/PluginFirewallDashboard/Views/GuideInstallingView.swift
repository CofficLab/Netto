import LumiUI
import SwiftUI

/// 系统扩展安装进行中：只展示进度，操作与状态由弹窗头部承载。
struct InstallingView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "gearshape.arrow.triangle.2.circlepath",
            title: "Installing System Extension",
            iconColor: .orange
        ) {
            VStack(spacing: AppUI.Spacing.sm) {
                ProgressView()
                    .controlSize(.small)

                Text("Please wait. This view updates automatically when installation completes.")
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
