import Combine
import Foundation
import MagicCore
import OSLog
import SwiftUI

@MainActor
class DataProvider: ObservableObject, SuperLog {
    nonisolated static let emoji = "💾"

    @Published var apps: [SmartApp] = []
    @Published var samples: [SmartApp] = SmartApp.samples
    @Published var status: FilterStatus = .disabled

    private var cancellables = Set<AnyCancellable>()
    private let appPermissionService: PermissionService
    private let firewallEventService: EventService

    /// 初始化DataProvider
    /// - Parameters:
    ///   - appPermissionService: 应用权限服务
    ///   - firewallEventService: 防火墙事件服务
    init(appPermissionService: PermissionService,
         firewallEventService: EventService) {
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
    private func updateAppsList(app: SmartApp) {
        // 检查应用是否已在列表中
        let appExists = apps.firstIndex(where: { $0.id == app.id }) != nil

        if appExists == false {
            self.apps.append(app)
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
    private func handleNetworkFlow(_ wrapper: FlowWrapper, verbose: Bool = false) {
        Task(priority: .background) {
            let event = FirewallEvent(
                address: wrapper.getAddress(),
                port: wrapper.getPort(),
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
        }

        self.updateAppsList(app: wrapper.getApp())
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 600)
}
