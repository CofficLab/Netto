import NetworkExtension
import SwiftUI

struct EventList: View {
    @EnvironmentObject private var app: AppManager
    @State private var selectedDirection: DirectionFilter = .all
    @State private var selectedStatus: StatusFilter = .all

    /// 根据筛选条件过滤events
    private var filteredEvents: [FirewallEvent] {
        let allEvents = app.events.reversed()

        return allEvents.filter { event in
            // 方向筛选
            let directionMatch: Bool
            switch selectedDirection {
            case .all:
                directionMatch = true
            case .inbound:
                directionMatch = event.direction == .inbound
            case .outbound:
                directionMatch = event.direction == .outbound
            }

            // 状态筛选
            let statusMatch: Bool
            switch selectedStatus {
            case .all:
                statusMatch = true
            case .allowed:
                statusMatch = event.status == .allowed
            case .rejected:
                statusMatch = event.status == .rejected
            }

            return directionMatch && statusMatch
        }
    }

    var body: some View {
        VStack {
            // 筛选控件
            HStack {
                Text("筛选条件:")
                    .font(.headline)

                Spacer().frame(width: 20)

                // 方向筛选
                Picker("Direction", selection: $selectedDirection) {
                    ForEach(DirectionFilter.allCases, id: \.self) { direction in
                        Text(direction.rawValue).tag(direction)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)

                Spacer().frame(width: 20)

                // 状态筛选
                Picker("Status", selection: $selectedStatus) {
                    ForEach(StatusFilter.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 160)

                Spacer()

                // 显示当前筛选结果数量
                Text("共 \(filteredEvents.count) 条记录")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            Table(filteredEvents, columns: {
                TableColumn("Time", value: \.timeFormatted).width(132)
                TableColumn("APP") { event in
                    let smartApp = SmartApp.fromId(event.sourceAppIdentifier)
                    HStack {
                        smartApp.icon.frame(width: 33)
                        Text(smartApp.name)
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
        .frame(minWidth: 700)
        .frame(minHeight: 500).onReceive(NotificationCenter.default.publisher(for: .NetWorkFilterFlow)) { notification in
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
