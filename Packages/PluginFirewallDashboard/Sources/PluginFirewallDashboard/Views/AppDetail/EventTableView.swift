import LumiUI
import ProviderFirewallEvents
import SwiftUI

struct EventTableView: View {
    let events: [FirewallEventSnapshot]
    let isLoading: Bool

    var body: some View {
        ZStack {
            if isLoading {
                SkeletonLoadingView()
            } else if events.isEmpty {
                EmptyStateView(title: String(localized: "No event data"))
            } else {
                Table(events, columns: {
                    TableColumn("Time", value: \.timeFormatted).width(150)
                    TableColumn("Address", value: \.address)
                    TableColumn("Port", value: \.port).width(60)
                    TableColumn("Direction") { event in
                        Text(event.direction == .inbound ? String(localized: "In") : String(localized: "Out"))
                            .foregroundStyle(event.isAllowed ? .green : .red)
                    }.width(60)
                    TableColumn("Status") { event in
                        Text(event.status == .allowed ? String(localized: "Allow") : String(localized: "Deny"))
                            .foregroundStyle(event.isAllowed ? .green : .red)
                    }.width(60)
                })
                .frame(minHeight: 200)
                .frame(maxHeight: 300)
            }
        }
    }
}

// MARK: - Preview

#Preview("大屏幕") {
    ContentView()
        .dashboardPreviewRoot()
        .frame(width: 600, height: 1000)
}

#Preview("小屏幕") {
    ContentView()
        .dashboardPreviewRoot()
        .frame(width: 500, height: 800)
}
