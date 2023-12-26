import OSLog
import SwiftUI

struct AppList: View {
    @State private var apps: [SmartApp] = []
    private var channel = Channel()
    private var appsVisible: [SmartApp] {
        apps.sorted(by: {
            $0.events.count > $1.events.count
        }).filter({
            $0.events.count > 0
        })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(appsVisible) { app in
                    AppLine(app: app)
                    Divider()
                }
            }
        }
        .background(Color.white.opacity(0.95))
        .onAppear {
            apps = SmartApp.appList
            onNewEvent()
        }
    }

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
