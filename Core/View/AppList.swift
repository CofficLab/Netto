import MagicCore
import OSLog
import SwiftUI

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
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array((apps.isNotEmpty ? apps : data.samples).enumerated()), id: \.element.id) { index, app in
                        AppLine(app: app)
                        if index < (apps.isNotEmpty ? apps : data.samples).count - 1 {
                            Divider()
                        }
                    }
                }
            }

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
