import AlertToast
import MagicCore
import SwiftData
import SwiftUI
import OSLog

struct RootView<Content>: View, SuperLog, SuperEvent where Content: View {
    nonisolated static var emoji: String { "🌳" }
    
    private var content: Content
    private var app = UIProvider.shared
    private var p = PluginProvider.shared
    private var data = DataProvider.shared
    private var channel = FirewallService.shared

    @StateObject var m = MessageProvider.shared

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .environmentObject(app)
            .environmentObject(data)
            .environmentObject(channel)
            .modelContainer(DatabaseManager.container())
            .environmentObject(m)
            .environmentObject(p)
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
