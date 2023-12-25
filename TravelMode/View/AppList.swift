import SwiftUI

struct AppList: View {
    private var channel = Channel()
    @State private var apps: [Activity] = []
    
    var body: some View {
        VStack {
            Table(apps, columns: {
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
