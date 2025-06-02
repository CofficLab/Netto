import MagicCore
import OSLog
import SwiftUI

struct AppList: View, SuperLog {
    @EnvironmentObject private var ui: UIProvider
    @EnvironmentObject private var data: DataProvider
    @EnvironmentObject private var channel: ChannelProvider

    nonisolated static let emoji = "🖥️"

    /// 获取主应用列表（过滤掉子应用，只显示顶级应用）
    private var apps: [SmartApp] {
        data.apps.sorted(by: {
            $0.events.count > $1.events.count
        })
//        .filter({
//            $0.events.count > 0 || data.shouldDeny($0.id)
//        })
        .filter({
            if ui.showSystemApps {
                return true
            } else {
                return $0.isSystemApp == false
            }
        })
        .filter({
            $0.hasId
        })
        .filter {
            switch ui.displayType {
            case .All:
                true
            case .Allowed:
                data.shouldAllow($0.id)
            case .Rejected:
                !data.shouldAllow($0.id)
            }
        }
        // 只显示主应用（没有父应用的应用），子应用通过折叠方式在AppInfo中展示
        .filter { app in
            // 检查是否为顶级应用（不是其他应用的子应用）
            !data.apps.contains { parentApp in
                parentApp.children.contains { $0.id == app.id }
            }
        }
    }

    /// 构建应用列表视图
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array((apps.isNotEmpty ? apps : data.samples).enumerated()), id: \.element.id) { index, app in
                        AppInfo(app: app)
                        if index < (apps.isNotEmpty ? apps : data.samples).count - 1 {
                            Divider()
                        }
                    }
                }
            }

            if channel.status.isNotRunning() || apps.isEmpty {
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
