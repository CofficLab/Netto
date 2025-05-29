import OSLog
import SwiftUI

struct AppListSample: View {
    @EnvironmentObject var data: DataProvider
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(data.apps) { app in
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
