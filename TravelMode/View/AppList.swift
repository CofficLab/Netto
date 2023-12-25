import SwiftUI

struct AppList: View {
    @State private var apps: [Activity] = []
    private var channel = Channel()
    private var appsVisible: [Activity] {
        apps.filter({
            $0.events.count > 0
        })
    }
    
    var body: some View {
        VStack {
            Table(appsVisible, columns: {
                TableColumn("名称") {
                    Image(nsImage: $0.appIcon)
                }
                TableColumn("名称", value: \.appName)
                TableColumn("ID", value: \.appId)
                TableColumn("事件") { app in
                    Text("\(app.events.count)")
                }
            })
        }
        .onAppear {
            apps = AppHelper.getRunningAppList().map({
                Activity(app: $0)
            })
            
            onNewEvent()
        }
    }
    
    private func onNewEvent() {
        EventManager().onNetworkFilterFlow({ e in
            print(e.description)
            if let app = AppHelper.getApp(e.sourceAppIdentifier) {
                for (i, a) in apps.enumerated() {
                    if a.appId == app.appId {
                        apps[i] = a.appendEvent(e)
                    }
                }
                
                apps = apps.sorted(by: {
                    $0.events.count > $1.events.count
                })
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
