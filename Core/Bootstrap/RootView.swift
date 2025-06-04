import AlertToast
import MagicCore
import OSLog
import SwiftData
import SwiftUI

struct RootView<Content>: View, SuperLog, SuperEvent where Content: View {
    nonisolated static var emoji: String { "🌳" }

    private var content: Content
    private var app = UIProvider.shared
    private var p = PluginProvider.shared
    private var data: DataProvider
    private var service: ServiceProvider

    @StateObject var m = MessageProvider.shared

    init(@ViewBuilder content: () -> Content) {
        os_log("\(Self.onInit)")
        self.content = content()
        
        // 使用共享的核心服务，避免重复初始化
        let coreServices = RootBox.shared
        self.data = coreServices.data
        self.service = coreServices.service
    }

    var body: some View {
        content
            .environmentObject(app)
            .environmentObject(data)
            .environmentObject(m)
            .environmentObject(p)
            .environmentObject(service)
            .onAppear(perform: onAppear)
            .onReceive(self.nc.publisher(for: .FilterStatusChanged), perform: onFilterStatusChanged)
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

// MARK: - Event

extension RootView {
    func onAppear() {
        self.data.status = service.getFirewallServiceStatus()
    }

    func onFilterStatusChanged(_ n: Notification) {
        if let status = n.object as? FilterStatus {
            os_log("\(self.t)状态变更为 -> \(status.description)")
            self.data.status = status
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
