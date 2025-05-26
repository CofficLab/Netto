import SwiftUI
import MagicCore
import OSLog

struct BtnStart: View, SuperLog {
    @EnvironmentObject private var channel: ChannelProvider
    @EnvironmentObject var m: MessageProvider

    var body: some View {
        MagicButton(icon: "restart.circle", size: .auto, action: {
            Task {
                do {
                    try await channel.startFilter(reason: self.className)
                } catch (let error) {
                    os_log("\(self.t)开启过滤器失败 -> \(error.localizedDescription)")
                    m.error(error)
                }
            }
        })
        .magicTitle("开启")
        .magicShape(.roundedRectangle)
        .frame(width: 150)
        .frame(height: 50)
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
