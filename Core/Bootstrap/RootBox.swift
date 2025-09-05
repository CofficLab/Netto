import OSLog
import SwiftData
import MagicCore

/**
 * 核心服务管理器
 * 用于集中管理应用程序的核心服务和提供者，避免重复初始化
 * 配合 RootView 使用
 */
@MainActor
final class RootBox: SuperLog {
    static let shared = RootBox(reason: "Shared")
    nonisolated static let emoji = "🚉"
    
    let data: DataProvider
    let service: ServiceProvider
    let message: MagicMessageProvider
    
    private init(reason: String) {
        os_log("\(Self.onInit)(\(reason))")
        
        // Repos
        let dbManager = DBManager.shared
        let appSettingRepo = dbManager.appSettingRepo
        let firewallRepo = dbManager.eventRepo
        
        // Services
        let appPermissionService = PermissionService(repo: appSettingRepo)
        let firewallEventService = EventService(repo: firewallRepo)
        let firewallService = FirewallService(appPermissionService: appPermissionService, reason: Self.author)
        let versionService = VersionService()
        
        // Providers
        self.data = DataProvider(appPermissionService: appPermissionService, firewallEventService: firewallEventService)
        self.service = ServiceProvider(firewallService: firewallService, firewallEventService: firewallEventService, versionService: versionService)
        self.message = MagicMessageProvider.shared
    }
}
