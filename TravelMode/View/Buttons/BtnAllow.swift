import SwiftUI
import MagicKit
import OSLog

struct BtnAllow: View, SuperLog {
    @EnvironmentObject private var channel: ChannelProvider
    @EnvironmentObject var m: MessageProvider
    
    var appId: String

    var body: some View {
        Button {
            do {
                try AppSetting.setAllow(appId)
                self.m.done("Allowed")
            } catch (let error) {
                os_log("\(self.t)操作失败 -> \(error.localizedDescription)")
                m.error(error)
            }
        } label: {
            Label("Allow", systemImage: "checkmark.circle.fill")
        }
        .controlSize(.extraLarge)
        .foregroundColor(.green)
        .cornerRadius(8)
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
