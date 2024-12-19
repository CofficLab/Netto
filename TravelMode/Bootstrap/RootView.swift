import SwiftUI
import SwiftData
import AlertToast
import MagicKit

struct RootView<Content>: View, SuperLog, SuperEvent where Content: View {
    private var content: Content
    private var appManager = AppManager()
    private var eventManager = EventManager()
    private var p = PluginProvider()
    
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
            .modelContainer(AppConfig.container)
            .environmentObject(m)
            .environmentObject(p)
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
            .onReceive(nc.publisher(for: .willInstall), perform: onWillInstall)
            .onReceive(nc.publisher(for: .didFailWithError), perform: onDidFailWithError)
    }
}

extension RootView {
    func onWillInstall(_ n: Notification) {
        self.m.append("安装系统扩展")
    }

    func onDidFailWithError(_ n: Notification) {
        guard let error = n.userInfo?["error"] as? Error else {
            self.m.append("安装系统扩展失败: 未知错误")
            return
        }

        self.m.append("安装系统扩展失败: \(error.localizedDescription)")
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
