import SwiftUI

struct BtnInstall: View {
    @EnvironmentObject private var channel: ChannelProvider

    var body: some View {
        Button("安装系统扩展") {
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
