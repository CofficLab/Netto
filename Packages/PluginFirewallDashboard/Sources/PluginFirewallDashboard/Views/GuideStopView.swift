import LumiUI
import SwiftUI

/// 停止监控视图：说明当前放行状态，开启动作由弹窗头部承载。
struct StopView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "shield.slash",
            title: "所有应用可自由联网",
            iconColor: .orange
        ) {
            Text("点击右上角「开启」开始拦截未授权联网。")
                .font(.appBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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
