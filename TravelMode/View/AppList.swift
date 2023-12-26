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
        VStack {
            Table(appsVisible, columns: {
                TableColumn("名称") { smartApp in
                    HStack {
                        smartApp.icon.frame(width: 33)
                        smartApp.nameView
                    }
                }
                TableColumn("ID", value: \.id)
                TableColumn("事件") { app in
                    Text("\(app.events.count)")
                }
                TableColumn("操作") { i in
                    if AppSetting.shouldAllow(i.id) {
                        HStack {
                            Image("dot_green").scaleEffect(0.5)
                            Button("禁止") {
                                AppSetting.setDeny(i.id)
                            }
                        }
                    } else {
                        HStack {
                            Image("dot_red").scaleEffect(0.5)
                            Button("允许") {
                                AppSetting.setAllow(i.id)
                            }
                        }
                    }
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
