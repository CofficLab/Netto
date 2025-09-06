import Combine
import Foundation
import MagicCore
import OSLog
import SwiftUI

@MainActor
class DataProvider: ObservableObject, SuperLog {
    nonisolated static let emoji = "💾"

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
        
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 600)
}
