import SwiftUI
import MagicCore
import OSLog
import NetworkExtension

struct AppDetail: View, SuperLog {
    nonisolated static let emoji = "🖥️"
    
    @EnvironmentObject var data: DataProvider
    
    @Binding var popoverHovering: Bool
    @State private var appeared = false

    var app: SmartApp

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 应用信息视图
            AppInfoView(app: app)
            
            // 事件详细列表
            EventDetailView(appId: app.id)
        }
        .padding(12)
        .onAppear {
            self.appeared = true
        }
        .onHover { hovering in
            popoverHovering = hovering
        }
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}

#Preview("防火墙事件视图") {
    RootView {
        DBEventView()
    }
    .frame(width: 600, height: 600)
}

#Preview("APP配置") {
    RootView {
        DBSettingView()
    }
    .frame(width: 600, height: 800)
}
