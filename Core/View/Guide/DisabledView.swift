import SwiftUI

struct DisabledView: View {
    var body: some View {
        Popview(
            iconName: "pause.circle",
            title: "已暂停",
            iconColor: .orange
        ) {
            BtnStart()
        }
    }
}

#Preview {
    RootView {
        DisabledView()
    }
    .frame(height: 500)
}

#Preview("App") {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
