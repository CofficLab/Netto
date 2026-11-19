import LumiUI
import SwiftUI

/// 停止监控视图：状态提示 + 重新开启。
struct StopView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "stop.circle",
            title: "监控已停止",
            iconColor: .orange
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                AppStatusBanner(kind: .info, title: "所有应用可自由联网")
                BtnStart()
            }
        }
    }
}

#Preview("APP") {
    ContentView()
        .dashboardPreviewRoot()
        .frame(height: 600)
}

#Preview {
    StopView()
        .dashboardPreviewRoot()
        .frame(height: 400)
}
