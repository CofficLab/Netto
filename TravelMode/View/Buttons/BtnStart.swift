import SwiftUI
import MagicKit
import OSLog

struct BtnStart: View, SuperLog {
    @EnvironmentObject private var channel: ChannelProvider
    @EnvironmentObject var m: MessageProvider

    var body: some View {
        Button {
            Task {
                do {
                    try await channel.startFilter(reason: self.className)
                } catch (let error) {
                    os_log("\(self.t)开启过滤器失败 -> \(error.localizedDescription)")
                    m.error(error)
                }
            }
        } label: {
            Label {
                            Text("开始")
                        } icon: {
                            Image("dot_green")
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
