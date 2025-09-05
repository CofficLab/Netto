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
    
    public var eventRepo: EventRepo
    private let appSettingRepo: AppSettingRepo

    /// 初始化DataProvider
    /// - Parameters:
    ///   - appPermissionService: 应用权限服务
    ///   - firewallEventService: 防火墙事件服务
    init(appPermissionService: PermissionService,
         firewallEventService: EventService, eventRepo: EventRepo, settingRepo: AppSettingRepo) {
        self.appPermissionService = appPermissionService
        self.firewallEventService = firewallEventService
        self.eventRepo = eventRepo
        self.appSettingRepo = settingRepo

        setupNotificationListeners()
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
        let repo = self.eventRepo
        Task {
            let event = FirewallEvent(
                address: wrapper.getAddress(),
                port: wrapper.getPort(),
                sourceAppIdentifier: wrapper.id,
                status: wrapper.allowed ? .allowed : .rejected,
                direction: wrapper.direction
            )

            // 将事件存储到数据库
            do {
                try await repo.create(event)
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
