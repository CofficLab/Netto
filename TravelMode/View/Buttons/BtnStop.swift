import MagicKit
import SwiftUI

struct BtnStop: View, SuperLog {
    @EnvironmentObject private var channel: ChannelProvider
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var app: AppManager

    var body: some View {
        Button {
            Task {
                do {
                    try await channel.stopFilter(reason: self.className)
                    app.stop()
                } catch {
                    self.m.error(error)
                }
            }
        } label: {
            Label {
                Text("Stop")
            } icon: {
                Image("dot_red")
            .scaleEffect(0.55)
            }
        }
        .controlSize(.extraLarge)
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
