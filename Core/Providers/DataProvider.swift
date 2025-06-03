import Combine
import Foundation
import MagicCore
import OSLog
import SwiftUI

@MainActor
class DataProvider: ObservableObject, SuperLog {
    nonisolated static let emoji = "💾"
    
    static let shared = DataProvider()

    @Published var apps: [SmartApp] = []
    @Published var samples: [SmartApp] = SmartApp.samples

    private var cancellables = Set<AnyCancellable>()
    private let appPermissionService: AppPermissionService
    private let firewallEventService: FirewallEventService

    /// 初始化DataProvider
    /// - Parameters:
    ///   - appPermissionService: 应用权限服务
    ///   - firewallEventService: 防火墙事件服务
    private init(appPermissionService: AppPermissionService = AppPermissionService(),
         firewallEventService: FirewallEventService = FirewallEventService()) {
        self.appPermissionService = appPermissionService
        self.firewallEventService = firewallEventService

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
        self.init(appPermissionService: AppPermissionService(),
                  firewallEventService: FirewallEventService())
    }
}

// MARK: - Action

extension DataProvider {
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

    /// 更新应用列表（确保在主线程执行）
    /// - Parameters:
    ///   - app: 要更新或添加的应用
    ///   - verbose: 是否输出详细日志
    @MainActor
    private func updateAppsList(app: SmartApp, verbose: Bool) {
        // 检查应用是否已在列表中
        let appExists = apps.firstIndex(where: { $0.id == app.id }) != nil

        if appExists {
            if verbose {
                os_log("\(self.t)🍋 监听到网络流量，更新已知APP")
            }
        } else {
            if verbose {
                os_log("\(self.t)🛋️ 监听到网络流量，没见过这个APP，加入列表 -> \(app.id)")
            }
            // 直接在主线程上添加应用，不需要再次使用DispatchQueue.main.async
            self.apps.append(app)
        }

        let total = self.apps.count

        if verbose {
            os_log("\(self.t)📈 当前APP数量 -> \(total)")
        }
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
        let verbose = true
        let app = SmartApp.fromId(wrapper.id)

        // 验证和处理端口信息
        let validPort: String
        if wrapper.port.isEmpty {
            validPort = "0" // 默认端口
        } else if let portNumber = Int(wrapper.port), portNumber > 0 && portNumber <= 65535 {
            validPort = wrapper.port
        } else {
            validPort = "0" // 无效端口时使用默认值
        }

        // 验证地址信息
        let validAddress = wrapper.hostname.isEmpty ? "unknown" : wrapper.hostname

        let event = FirewallEvent(
            address: validAddress,
            port: validPort,
            sourceAppIdentifier: wrapper.id,
            status: wrapper.allowed ? .allowed : .rejected,
            direction: wrapper.direction
        )

        // 将事件存储到数据库
        do {
            try firewallEventService.recordEvent(event)
            if verbose {
                os_log("\(self.t)💾 事件已存储到数据库: \(event.description)")
            }
        } catch {
            os_log(.error, "\(self.t)❌ 存储事件到数据库失败: \(error)")
        }

        self.updateAppsList(app: app, verbose: verbose)
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 600)
}
