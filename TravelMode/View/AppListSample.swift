import OSLog
import SwiftUI

struct AppListSample: View {
    private var apps: [SmartApp] {
        [SmartApp(id: "DNS", name: "DNS服务", icon: Image("DNS"))] +
        Array(1...100).map({
            SmartApp(id: "app-\($0)", name: "APP-\($0)", icon: Image("Unknown"))
        })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(apps) { app in
                    AppLine(app: app)
                    Divider()
                }
            }
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

#Preview("AppListSample") {
    RootView {
        AppListSample()
    }
}

#Preview("EventList") {
    RootView {
        EventList()
    }
}
