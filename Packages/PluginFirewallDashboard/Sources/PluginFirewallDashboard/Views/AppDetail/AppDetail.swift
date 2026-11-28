import LumiUI
import NetworkExtension
import OSLog
import SwiftUI

struct AppDetail: View {
    nonisolated static let emoji = "🖥️"

    let showChart = false

    @Binding var popoverHovering: Bool

    var app: SmartApp

    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.Spacing.md) {
            // 应用信息视图
            AppInfoView(app: app)

            if showChart {
                // 联网趋势（按分钟）
                ChartView(appId: app.id, title: "")
            }

            // 事件详细列表
            EventDetailView(appId: app.id)
        }
        .padding(AppUI.Spacing.md)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("netpause.app.detail")
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
