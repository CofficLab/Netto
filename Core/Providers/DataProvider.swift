import Combine
import Foundation
import MagicCore
import OSLog
import SwiftUI

class DataProvider: ObservableObject, SuperLog {
    static let shared = DataProvider()
    static let emoji = "💾"

    @Published var apps: [SmartApp] = []
    @Published var samples: [SmartApp] = SmartApp.samples
    @Published var events: [FirewallEvent] = []

    private var cancellables = Set<AnyCancellable>()
    private let appPermissionService: AppPermissionService

    /// 初始化DataProvider
    /// - Parameter appPermissionService: 应用权限服务，默认使用shared实例
    init(appPermissionService: AppPermissionService = AppPermissionService.shared) {
        self.appPermissionService = appPermissionService

        // 添加被禁止的应用到apps列表中
        do {
            let deniedAppIds = try appPermissionService.getDeniedApps()
            for appId in deniedAppIds {
                let smartApp = SmartApp.fromId(appId)
                if !self.apps.contains(where: { $0.id == smartApp.id }) {
                    self.apps.append(smartApp)
                }
            }
        } catch {
            os_log(.error, "\(self.t)获取被禁止应用列表失败: \(error)")
        }

        setupNotificationListeners()
    }

    /// 私有初始化方法，用于单例模式
    private convenience init() {
        self.init(appPermissionService: AppPermissionService.shared)
    }

    func appendEvent(_ e: FirewallEvent) {
        self.events.append(e)

        if self.events.count > 100 {
            self.events.removeFirst()
        }
    }

    /// 检查应用是否应该被允许访问网络
    /// - Parameter id: 应用标识符
    /// - Returns: 是否允许访问
    func shouldAllow(_ id: String) -> Bool {
        return appPermissionService.shouldAllow(id)
    }

    /// 检查应用是否应该被拒绝访问网络
    /// - Parameter id: 应用标识符
    /// - Returns: 是否拒绝访问
    func shouldDeny(_ id: String) -> Bool {
        return !self.shouldAllow(id)
    }

    /// 允许应用访问网络
    /// - Parameter id: 应用标识符
    /// - Throws: 操作失败时抛出错误
    func allow(_ id: String) throws {
        try appPermissionService.allow(id)
    }

    /// 拒绝应用访问网络
    /// - Parameter id: 应用标识符
    /// - Throws: 操作失败时抛出错误
    func deny(_ id: String) throws {
        try appPermissionService.deny(id)
    }
}

// MARK: - Event

extension DataProvider {
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
        let verbose = false
        let flow = wrapper.flow
        let app = SmartApp.fromId(flow.getAppId())
        let event = FirewallEvent(
            address: flow.getHostname(),
            port: flow.getLocalPort(),
            sourceAppIdentifier: flow.getAppId(),
            status: wrapper.allowed ? .allowed : .rejected,
            direction: flow.direction
        )

        self.appendEvent(event)

        if let index = apps.firstIndex(where: { $0.id == app.id }) {
            if verbose {
                os_log("\(self.t)🍋 监听到网络流量，为已知的APP增加Event")
            }

            apps[index] = apps[index].appendEvent(event)
            apps[index] = apps[index].addChildren(app.children)
        } else {
            if verbose {
                os_log("\(self.t)🛋️ 监听到网络流量，没见过这个APP，加入列表 -> \(app.id)")
            }

            apps.append(app.appendEvent(event))
        }

        let total = self.apps.count
        let hasEventCount = self.apps.filter({ $0.events.count > 0 }).count

        if verbose {
            os_log("\(self.t)📈 当前APP数量 -> \(total) 其中 Events.Count>0 的数量 -> \(hasEventCount)")
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 600)
}
