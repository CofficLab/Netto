import SwiftUI

struct BtnInstall: View {
    @EnvironmentObject private var channel: Channel

    var body: some View {
        Button("安装") {
            channel.installFilter()
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
