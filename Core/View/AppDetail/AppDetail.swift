import SwiftUI
import MagicCore
import OSLog
import NetworkExtension

struct AppDetail: View, SuperLog {
    nonisolated static let emoji = "🖥️"
    
    let showChart = false
    
    @Binding var popoverHovering: Bool

    var app: SmartApp

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 应用信息视图
            AppInfoView(app: app)

            if showChart {
                // 联网趋势（按分钟）
                ChartView(appId: app.id, title: "")
            }

            Divider()
            
            // 事件详细列表
            EventDetailView(appId: app.id)
        }
        .padding(12)
        .onHover { hovering in
            popoverHovering = hovering
        }
    }
}

#Preview("APP") {
    RootView(environment: .preview()) {
        ContentView()
    }
    .frame(height: 600)
}

#Preview("防火墙事件视图") {
    RootView(environment: .preview()) {
        DBEventView()
    }
    .frame(width: 600, height: 600)
}

#Preview("APP配置") {
    RootView(environment: .preview()) {
        DBSettingView()
    }
    .frame(width: 600, height: 800)
}
