import SwiftUI
import SwiftData
import AlertToast
import MagicCore

struct RootView<Content>: View, SuperLog, SuperEvent where Content: View {
    private var content: Content
    private var app = AppManager.shared
    private var eventManager = EventManager()
    private var p = PluginProvider()
    
    @StateObject var m = MessageProvider()
    @StateObject var channel = ChannelProvider()

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environmentObject(app)
            .environmentObject(channel)
            .environmentObject(eventManager)
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
            .onReceive(nc.publisher(for: .willInstall), perform: onWillInstall)
            .onReceive(nc.publisher(for: .didFailWithError), perform: onDidFailWithError)
            .onReceive(nc.publisher(for: .didInstall), perform: onDidInstall)
            .onReceive(nc.publisher(for: .willStart), perform: onWillStart)
            .onReceive(nc.publisher(for: .didStart), perform: onDidStart)
            .onReceive(nc.publisher(for: .willStop), perform: onWillStop)
            .onReceive(nc.publisher(for: .didStop), perform: onDidStop)
            .onReceive(nc.publisher(for: .configurationChanged), perform: onConfigurationChanged)
            .onReceive(nc.publisher(for: .needApproval), perform: onNeedApproval)
            .onReceive(nc.publisher(for: .willRegisterWithProvider), perform: onWillRegisterWithProvider)
            .onReceive(nc.publisher(for: .didRegisterWithProvider), perform: onDidRegisterWithProvider)
    }
}

extension RootView {
    func onWillInstall(_ n: Notification) {
        self.m.append("安装系统扩展")
    }

    func onDidInstall(_ n: Notification) {
        self.m.append("安装系统扩展成功")
    }

    func onWillStart(_ n: Notification) {
        self.m.append("开始监控")
    }

    func onDidStart(_ n: Notification) {
        self.m.append("开始监控成功")
    }

    func onWillStop(_ n: Notification) {
        self.m.append("停止监控")
    }

    func onDidStop(_ n: Notification) {
        self.m.append("停止监控成功")
    }

    func onConfigurationChanged(_ n: Notification) {
        self.m.append("配置发生变化")
    }

    func onNeedApproval(_ n: Notification) {
        self.m.append("需要用户批准")
    }

    func onWillRegisterWithProvider(_ n: Notification) {
        self.m.append("将要注册系统扩展")
    }

    func onDidRegisterWithProvider(_ n: Notification) {
        self.m.append("注册系统扩展成功")
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
