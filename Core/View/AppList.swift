import OSLog
import SwiftUI

struct AppList: View {
    @EnvironmentObject private var appManager: AppManager
    @EnvironmentObject private var channel: ChannelProvider
    @EnvironmentObject private var data: DataProvider
    
    private var displayType: DisplayType {
        appManager.displayType
    }

    private var appsVisible: [SmartApp] {
        data.apps.sorted(by: {
            $0.events.count > $1.events.count
        }).filter({
            $0.events.count > 0
        }).filter {
            switch displayType {
            case .All:
                true
            case .Allowed:
                AppSetting.shouldAllow($0.id)
            case .Rejected:
                !AppSetting.shouldAllow($0.id)
            }
        }
    }

    var body: some View {
        ZStack {
            if appsVisible.count > 0 {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(appsVisible) { app in
                            AppLine(app: app)
                            Divider()
                        }
                    }
                }
            } else {
                AppListSample()
            }

            if appsVisible.count == 0 || appManager.status.isStopped() {
                GuideView()
            }
        }
        .onAppear {
            onNewEvent()
        }
    }
}

// MARK: Event

extension AppList {
    private func onNewEvent() {
        EventManager.shared.onNetworkFilterFlow({ e in
            let app = SmartApp.fromId(e.sourceAppIdentifier)
            if data.apps.contains(where: {
                $0.id == app.id
            }) {
                for (i, a) in data.apps.enumerated() {
                    if a.id == app.id {
                        data.apps[i] = a.appendEvent(e)
                    }
                }
            } else {
                data.apps.append(app)
            }
        })
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
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
