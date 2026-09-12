import SwiftUI

struct UnknownView: View {
    var body: some View {
        Popview(
            iconName: "questionmark.circle",
            title: "当前状态未知"
        ) {
            EmptyView()
        }
    }
}

#Preview {
    RootView(environment: .preview()) {
        UnknownView()
    }
    .frame(height: 500)
}

#Preview {
    RootView(environment: .preview()) {
        ContentView()
    }
    .frame(height: 800)
}
