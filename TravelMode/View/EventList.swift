import SwiftUI

struct EventList: View {
    @EnvironmentObject private var app: AppManager
    private var events: [FirewallEvent] {
        app.events.reversed()
    }

    var body: some View {
        VStack {
            Table(events, columns: {
                TableColumn("时间", value: \.timeFormatted)
                TableColumn("APP") { event in
                    let wrapper = AppHelper.getApp(event.sourceAppIdentifier)
                    HStack {
                        if let wrapper = wrapper {
                            Image(nsImage: wrapper.appIcon)
                            Text(wrapper.appName)
                        }
                    }
                }
                TableColumn("ID", value: \.sourceAppIdentifier)
                TableColumn("地址", value: \.address)
                TableColumn("端口", value: \.port)
                TableColumn("状态") { e in
                    Text(e.statusDescription)
                        .foregroundStyle(e.isAllowed ? .green : .red)
                }
            })
        }
        .onAppear {
            EventManager().onNetworkFilterFlow({
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
