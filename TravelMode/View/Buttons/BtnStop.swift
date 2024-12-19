import MagicKit
import SwiftUI

struct BtnStop: View, SuperLog {
    @EnvironmentObject private var channel: ChannelProvider
    @EnvironmentObject var m: MessageProvider

    var body: some View {
        Button("停止") {
            Task {
                do {
                    try await channel.stopFilter(reason: self.className)
                } catch {
                    self.m.error(error)
                }
            }
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
