import OSLog
import SwiftUI
import MagicCore

struct AppList: View {
    @EnvironmentObject private var ui: UIProvider
    @EnvironmentObject private var data: DataProvider

    private var apps: [SmartApp] {
        data.apps.sorted(by: {
            $0.events.count > $1.events.count
        }).filter({
            $0.events.count > 0 || !data.shouldAllow($0.id)
        }).filter {
            switch ui.displayType {
            case .All:
                true
            case .Allowed:
                data.shouldAllow($0.id)
            case .Rejected:
                !data.shouldAllow($0.id)
            }
        }
    }

    /// 构建应用列表视图
    /// - 使用List替代ScrollView提供更好的性能和用户体验
    /// - 当应用列表为空或服务未运行时显示引导视图
    var body: some View {
        ZStack {
            List {
                ForEach(apps.isNotEmpty ? apps : data.samples) { app in
                    AppLine(app: app)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.visible)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            
            if ui.status.isNotRunning() || apps.isEmpty {
                GuideView()
            }
        }
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}

#Preview("AppList") {
    RootView {
        AppList()
    }
}

#Preview("EventList") {
    RootView {
        EventList()
    }
}
