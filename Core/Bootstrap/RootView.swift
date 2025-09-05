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

    @StateObject var m = MagicMessageProvider.shared

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
            .withMagicToast()
            .environmentObject(app)
            .environmentObject(data)
            .environmentObject(m)
            .environmentObject(p)
            .environmentObject(service)
            .onAppear(perform: onAppear)
            .onReceive(self.nc.publisher(for: .FilterStatusChanged), perform: onFilterStatusChanged)
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

extension View {
    /// 将当前视图包裹在RootView中
    /// - Returns: 被RootView包裹的视图
    func inRootView() -> some View {
        RootView {
            self
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
