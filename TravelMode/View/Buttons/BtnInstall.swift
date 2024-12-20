import SwiftUI

struct BtnInstall: View {
    @EnvironmentObject private var channel: ChannelProvider

    var body: some View {
        Button("Install") {
            channel.installFilter()
        }.controlSize(.extraLarge)
    }
}

#Preview {
    RootView {
        ContentView()
    }
}

#Preview {
    RootView {
        BtnInstall()
    }
}
