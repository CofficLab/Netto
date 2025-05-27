import SwiftUI

struct RunningView: View {
    var body: some View {
        Popview(
            iconName: "inset.filled.rectangle.badge.record",
            title: "正在监控",
            iconColor: .green
        ) {
            Text("Apps connected to the internet will appear here")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    RootView {
        RunningView()
    }
    .frame(height: 500)
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
