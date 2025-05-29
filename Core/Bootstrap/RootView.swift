import AlertToast
import MagicCore
import SwiftData
import SwiftUI

struct RootView<Content>: View, SuperLog, SuperEvent where Content: View {
    private var content: Content
    private var app = AppManager.shared
    private var p = PluginProvider.shared
    private var data = DataProvider.shared

    @StateObject var m = MessageProvider.shared
    @StateObject var channel = ChannelProvider.shared

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .environmentObject(app)
            .environmentObject(data)
            .environmentObject(channel)
            .modelContainer(AppConfig.container)
            .environmentObject(m)
            .environmentObject(p)
            .toast(isPresenting: $m.showToast, alert: {
                AlertToast(type: .systemImage("info.circle", .blue), title: m.toast)
            }, completion: {
                m.clearToast()
            })
            .toast(isPresenting: $m.showAlert, alert: {
                AlertToast(displayMode: .alert, type: .error(.red), title: m.alert)
            }, completion: {
                m.clearAlert()
            })
            .toast(isPresenting: $m.showDone, alert: {
                AlertToast(type: .complete(.green), title: m.doneMessage)
            }, completion: {
                m.clearDoneMessage()
            })
            .toast(isPresenting: $m.showError, duration: 0, tapToDismiss: true, alert: {
                AlertToast(displayMode: .alert, type: .error(.indigo), title: m.error?.localizedDescription)
            }, completion: {
                m.clearError()
            })

    }
}



#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
