import SwiftUI

struct EventList: View {
    @EnvironmentObject private var app:AppManager
    private var angel = Channel()
    private var events: [FirewallEvent] {
        app.events.reversed()
    }
    
    var body: some View {
        VStack {
            Table(events, columns: {
                TableColumn("时间", value: \.timeFormatted)
                TableColumn("APP", value: \.sourceAppIdentifier)
                TableColumn("地址", value: \.address)
                TableColumn("端口", value: \.port)
            })
        }
        .onAppear {
            angel.viewWillAppear()
            Event().onNetworkFilterFlow({
                app.appendEvent($0)
            })
        }
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
}

#Preview {
    RootView {
        EventList()
    }
}
