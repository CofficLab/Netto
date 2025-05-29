import Combine
import Foundation
import SwiftUI
import OSLog

class DataProvider: ObservableObject {
    static let shared = DataProvider()

    @Published var apps: [SmartApp]
    private var cancellables = Set<AnyCancellable>()
    private let appPermissionService: AppPermissionService

    /// 初始化DataProvider
    /// - Parameter appPermissionService: 应用权限服务，默认使用shared实例
    init(appPermissionService: AppPermissionService = AppPermissionService.shared) {
        self.appPermissionService = appPermissionService
        self.apps = SmartApp.appList
        
        // 添加被禁止的应用到apps列表中
        do {
            let deniedAppIds = try appPermissionService.getDeniedApps()
            for appId in deniedAppIds {
                let smartApp = SmartApp.fromId(appId)
                // 检查apps中是否已经包含该应用，如果没有则添加
                if !self.apps.contains(where: { $0.id == smartApp.id }) {
                    self.apps.append(smartApp)
                }
            }
        } catch {
            print("获取被禁止应用列表失败: \(error)")
        }
        
        setupNotificationListeners()
    }

    /// 私有初始化方法，用于单例模式
    private convenience init() {
        self.init(appPermissionService: AppPermissionService.shared)
    }

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

    /// 检查应用是否应该被允许访问网络
    /// - Parameter id: 应用标识符
    /// - Returns: 是否允许访问
    func shouldAllow(_ id: String) -> Bool {
        return appPermissionService.shouldAllow(id)
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

    let samples: [SmartApp] = [
        SmartApp(id: "com.apple.Safari", name: "Safari", icon: Text("🌐")),
        SmartApp(id: "com.apple.Maps", name: "Maps", icon: Text("🗺️")),
        SmartApp(id: "com.apple.MobileSMS", name: "Messages", icon: Text("💬")),
        SmartApp(id: "com.apple.Mail", name: "Mail", icon: Text("📧")),
        SmartApp(id: "com.apple.Photos", name: "Photos", icon: Text("🖼️")),
        SmartApp(id: "com.apple.iCal", name: "Calendar", icon: Text("📅")),
        SmartApp(id: "com.apple.Notes", name: "Notes", icon: Text("📝")),
        SmartApp(id: "com.apple.reminders", name: "Reminders", icon: Text("⏰")),
        SmartApp(id: "com.apple.Weather", name: "Weather", icon: Text("🌤️")),
        SmartApp(id: "com.apple.Clock", name: "Clock", icon: Text("🕐")),
        SmartApp(id: "com.apple.systempreferences", name: "Settings", icon: Text("⚙️")),
        SmartApp(id: "com.apple.AppStore", name: "App Store", icon: Text("🏪")),
        SmartApp(id: "com.apple.Health", name: "Health", icon: Text("❤️")),
        SmartApp(id: "com.apple.Wallet", name: "Wallet", icon: Text("👛")),
        SmartApp(id: "com.apple.stocks", name: "Stocks", icon: Text("📈")),
        SmartApp(id: "com.apple.Calculator", name: "Calculator", icon: Text("🧮")),
        SmartApp(id: "com.apple.camera", name: "Camera", icon: Text("📸")),
        SmartApp(id: "com.apple.FaceTime", name: "FaceTime", icon: Text("📱")),
        SmartApp(id: "com.apple.iBooks", name: "iBooks", icon: Text("📚")),
        SmartApp(id: "com.apple.podcasts", name: "Podcasts", icon: Text("🎙️")),
        SmartApp(id: "com.apple.Music", name: "Music", icon: Text("🎵")),
        SmartApp(id: "com.apple.TV", name: "TV", icon: Text("📺")),
        SmartApp(id: "com.apple.finder", name: "Finder", icon: Text("📁")),
        SmartApp(id: "com.apple.Home", name: "Home", icon: Text("🏠")),
        SmartApp(id: "com.apple.VoiceMemos", name: "Voice Memos", icon: Text("🎤")),
        SmartApp(id: "com.apple.shortcuts", name: "Shortcuts", icon: Text("⚡️")),
        SmartApp(id: "com.apple.translate", name: "Translate", icon: Text("🌍")),
        SmartApp(id: "com.apple.findmy", name: "Find My", icon: Text("🔍")),
        SmartApp(id: "com.apple.AddressBook", name: "Address Book", icon: Text("👥")),
        SmartApp(id: "com.apple.measure", name: "Measure", icon: Text("📏")),
    ]
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
