import OSLog
import SwiftUI

struct AppList: View {
    @EnvironmentObject private var appManager: AppManager

    @State private var apps: [SmartApp] = []
    private var displayType: DisplayType {
        appManager.displayType
    }

    private var channel = ChannelProvider()
    private var appsVisible: [SmartApp] {
        apps.sorted(by: {
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
                    .shadow(color: Color.blue.opacity(0.2), radius: 10, x: 0, y: 2)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(minHeight: 300)
        .onAppear {
            apps = SmartApp.appList
            onNewEvent()
        }
    }
}

// MARK: Event

extension AppList {
    private func onNewEvent() {
        EventManager().onNetworkFilterFlow({ e in
            let app = SmartApp.fromId(e.sourceAppIdentifier)
            if apps.contains(where: {
                $0.id == app.id
            }) {
                for (i, a) in apps.enumerated() {
                    if a.id == app.id {
                        apps[i] = a.appendEvent(e)
                    }
                }
            } else {
                apps.append(app)
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
