import OSLog
import SwiftUI

struct AppList: View {
    @State private var apps: [SmartApp] = []
    private var channel = Channel()
    private var appsVisible: [SmartApp] {
        apps.sorted(by: {
            $0.events.count > $1.events.count
        })
    }

    var body: some View {
        VStack {
            Table(appsVisible, columns: {
                TableColumn("名称") { smartApp in
                    HStack {
                        smartApp.image.frame(width: 33)
                        smartApp.nameView
                    }
                }
                TableColumn("ID", value: \.id)
                TableColumn("事件") { app in
                    Text("\(app.events.count)")
                }
            })
        }
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
