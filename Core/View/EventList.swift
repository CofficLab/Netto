import SwiftUI

struct EventList: View {
    @EnvironmentObject private var app: AppManager
    private var events: [FirewallEvent] {
        app.events.reversed()
    }

    var body: some View {
        VStack {
            Table(events, columns: {
                TableColumn("Time", value: \.timeFormatted).width(132)
                TableColumn("APP") { event in
                    let smartApp = SmartApp.fromId(event.sourceAppIdentifier)
                    HStack {
                        smartApp.icon.frame(width: 33)
                        smartApp.nameView
                    }
                }
                TableColumn("ID", value: \.sourceAppIdentifier)
                TableColumn("Address", value: \.address)
                TableColumn("Port", value: \.port).width(60)
                TableColumn("Direction") { event in
                    Text("\(event.direction == .inbound ? "In" : "Out")")
                }.width(30)
                TableColumn("Status") { e in
                    Text(e.statusDescription)
                        .foregroundStyle(e.isAllowed ? .green : .red)
                }.width(30)
            })
        }
        .background(BackgroundView.type1)
        .onReceive(NotificationCenter.default.publisher(for: .NetWorkFilterFlow)) { notification in
            if let wrapper = notification.object as? FlowWrapper {
                let flow = wrapper.flow
                let event = FirewallEvent(
                    address: flow.getHostname(),
                    port: flow.getLocalPort(),
                    sourceAppIdentifier: flow.getAppId(),
                    status: wrapper.allowed ? .allowed : .rejected,
                    direction: flow.direction
                )
                app.appendEvent(event)
            }
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
