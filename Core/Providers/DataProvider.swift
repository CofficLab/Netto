import Foundation
import SwiftUI
import Combine

class DataProvider: ObservableObject {
    static let shared = DataProvider()
    private init() {
        self.apps = SmartApp.appList
        setupNotificationListeners()
    }
    
    @Published var apps: [SmartApp] = []
    private var cancellables = Set<AnyCancellable>()
    
    /// 设置通知监听器
    private func setupNotificationListeners() {
        NotificationCenter.default.publisher(for: .NetWorkFilterFlow)
            .compactMap { $0.object as? FlowWrapper }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] wrapper in
                self?.handleNetworkFlow(wrapper)
            }
            .store(in: &cancellables)
    }
    
    /// 处理网络流量事件
    /// - Parameter wrapper: 包装的网络流量数据
    private func handleNetworkFlow(_ wrapper: FlowWrapper) {
        let flow = wrapper.flow
        let app = SmartApp.fromId(flow.getAppId())
        
        if let index = apps.firstIndex(where: { $0.id == app.id }) {
            let event = FirewallEvent(
                address: flow.getHostname(),
                port: flow.getLocalPort(),
                sourceAppIdentifier: flow.getAppId(),
                status: wrapper.allowed ? .allowed : .rejected,
                direction: flow.direction
            )
            apps[index] = apps[index].appendEvent(event)
        } else {
            apps.append(app)
        }
    }
    
    func shouldAllow(_ id: String) -> Bool {
        return AppSetting.shouldAllow(id)
    }
    
    func allow(_ id: String) throws {
        try AppSetting.setAllow(id)
    }
    
    func deny(_ id: String) throws {
        try AppSetting.setDeny(id)
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
