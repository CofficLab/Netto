import SwiftUI
import SwiftData
import AlertToast

struct RootView<Content>: View where Content: View {
    private var content: Content
    private var appManager = AppManager()
    private var eventManager = EventManager()
    
    @StateObject var m = MessageProvider()
    @StateObject var channel = ChannelProvider()

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environmentObject(appManager)
            .environmentObject(channel)
            .environmentObject(eventManager)
            .modelContainer(DBConfig.container)
            .environmentObject(m)
            .frame(minWidth: 500, minHeight: 200)
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
