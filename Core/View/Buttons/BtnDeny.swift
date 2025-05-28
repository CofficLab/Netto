import SwiftUI
import MagicCore
import OSLog

struct BtnDeny: View, SuperLog {
    @EnvironmentObject private var channel: ChannelProvider
    @EnvironmentObject var m: MessageProvider
    
    var appId: String

    var body: some View {
        Button {
            do {
                try AppSetting.setDeny(appId)
                self.m.toast("Denied")
            } catch (let error) {
                os_log("\(self.t)操作失败 -> \(error.localizedDescription)")
                m.error(error)
            }
        } label: {
            Label("Deny", systemImage: "xmark.circle.fill")
        }
        .controlSize(.extraLarge)
        .foregroundColor(.red)
        .cornerRadius(8)
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
