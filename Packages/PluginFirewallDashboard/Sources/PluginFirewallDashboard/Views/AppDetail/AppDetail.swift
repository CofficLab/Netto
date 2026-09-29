import SwiftUI
import OSLog
import NetworkExtension

struct AppDetail: View {
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
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("netto.app.detail")
        .onHover { hovering in
            popoverHovering = hovering
        }
    }
}

#Preview("APP") {
    DashboardPreviewHost {
        ContentView()
    }
    .frame(height: 600)
}
