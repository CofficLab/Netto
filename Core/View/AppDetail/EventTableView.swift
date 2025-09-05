import SwiftUI

struct EventTableView: View {
    let events: [FirewallEventModel]
    @Binding var isLoading: Bool

    var body: some View {
        ZStack {
            if isLoading {
                SkeletonLoadingView()
            } else if events.isEmpty {
                EmptyStateView()
            } else {
                Table(events, columns: {
                    TableColumn("Time", value: \.timeFormatted).width(150)
                    TableColumn("Address", value: \.address)
                    TableColumn("Port", value: \.port).width(60)
                    TableColumn("Direction") { event in
                        Text(event.direction == .inbound ? "入" : "出")
                            .foregroundStyle(event.isAllowed ? .green : .red)
                    }.width(60)
                    TableColumn("Status") { event in
                        Text(event.status == .allowed ? "允许" : "拒绝")
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
        .inRootView()
        .frame(width: 600, height: 1000)
}

#Preview("小屏幕") {
    ContentView()
        .inRootView()
        .frame(width: 500, height: 800)
}
