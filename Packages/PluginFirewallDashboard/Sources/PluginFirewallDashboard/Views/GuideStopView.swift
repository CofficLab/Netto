import LumiUI
import SwiftUI

/// 停止监控视图：说明当前放行状态，开启动作由弹窗头部承载。
struct StopView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "shield.slash",
            title: "All Apps Can Access the Network Freely",
            iconColor: .orange
        ) {
            Text("Click \"Start\" in the top-right corner to begin blocking unauthorized network access.")
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
