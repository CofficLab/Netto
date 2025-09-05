import SwiftData
import OSLog
import MagicCore
import SwiftUI

/**
 * 数据库管理器
 * 
 * ## 概述
 * DatabaseManager作为整个应用程序数据库操作的统一入口点，负责管理数据库容器、上下文和Repository实例。
 * 它提供了一个集中化的数据库管理解决方案，确保数据访问的一致性和可靠性。
 *
 */
@MainActor
class DBManager: SuperLog {
    nonisolated static let emoji = "🏭"
    
    static let shared = DBManager()
    
    // MARK: - Properties
    
    /// 数据库维护定时器间隔（秒）
    private let maintenanceInterval: TimeInterval = 24 * 60 * 60 // 24小时
    
    /// 数据库容器
    private let container: ModelContainer
    
    /// 主上下文
    private let mainContext: ModelContext
    
    /// AppSetting仓库
    lazy var appSettingRepo: AppSettingRepo = {
        return AppSettingRepo(context: mainContext)
    }()
    
    /// FirewallEvent仓库
    lazy var eventRepo: EventRepo = {
        return EventRepo(context: mainContext)
    }()

    static func container() -> ModelContainer  {
        let schema = Schema([
            AppSetting.self,
            FirewallEventModel.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: AppConfig.databaseURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            return container
        } catch {
            fatalError("无法创建 primaryContainer: \n\(error)")
        }
    }
    
    // MARK: - Initialization
    
    /// 初始化数据库管理器
    /// - Parameter container: 数据库容器，如果为nil则使用默认配置
    private init(container: ModelContainer? = nil) {
        os_log("\(Self.onInit)")
        if let container = container {
            self.container = container
        } else {
            self.container = Self.container()
        }
        
        self.mainContext = ModelContext(self.container)
        
        // 配置上下文
        configureContext()
        
        // 启动定期清理任务
        self.startPeriodicCleanup()
        
        // 初始化时执行一次数据库维护
        Task {
            do {
                try await self.performDatabaseMaintenance()
            } catch {
                os_log("\(self.t)❌ 初始化数据库维护失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Context Management
    
    /// 配置数据库上下文
    private func configureContext() {
        // 设置自动保存策略
        mainContext.autosaveEnabled = true
    }
    
    /// 创建新的后台上下文
    /// - Returns: 新的ModelContext实例，用于后台操作
    func createBackgroundContext() -> ModelContext {
        return ModelContext(container)
    }
    
    /// 保存主上下文
    /// - Throws: 保存时可能抛出的错误
    func saveMainContext() throws {
        if mainContext.hasChanges {
            try mainContext.save()
        }
    }
    
    // MARK: - Database Operations
    
    /// 清空所有数据
    /// - Throws: 清空操作时可能抛出的错误
    func clearAllData() throws {
        // 删除所有AppSetting记录
        let appSettings = try mainContext.fetch(FetchDescriptor<AppSetting>())
        for setting in appSettings {
            mainContext.delete(setting)
        }
        
        // 删除所有FirewallEvent记录
        let firewallEvents = try mainContext.fetch(FetchDescriptor<FirewallEventModel>())
        for event in firewallEvents {
            mainContext.delete(event)
        }
        
        try saveMainContext()
        
        os_log("All database data cleared successfully")
    }
    
    /// 检查数据库健康状态
    /// - Returns: 数据库是否健康
    nonisolated func checkDatabaseHealth() async -> Bool {
        os_log("\(self.t)🔍 开始检查数据库健康状态")
        do {
            // 使用后台上下文执行健康检查
            let isHealthy = try await performBackgroundTask { context in
                // 尝试执行一个简单的查询来检查数据库连接
                _ = try context.fetch(FetchDescriptor<AppSetting>())
                return true
            }
            return isHealthy
        } catch {
            os_log("\(self.t)❌ 数据库健康检查失败: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 执行后台任务
    /// - Parameter task: 要执行的后台任务闭包
    /// - Throws: 任务执行时可能抛出的错误
    func performBackgroundTask<T: Sendable>(_ task: @escaping @Sendable (ModelContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            let backgroundContext = createBackgroundContext()
            
            Task {
                do {
                    let result = try task(backgroundContext)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Data Cleanup

extension DBManager {
    
    /// 清理所有应用超过30天的事件记录
    /// - Returns: 删除的总记录数量
    /// - Throws: 清理操作时可能抛出的错误
    nonisolated func cleanupOldFirewallEvents() async throws -> Int {
        os_log("\(self.t)🧹 开始清理过期的防火墙事件")
        return try await performBackgroundTask { context in
            let repository = EventRepo(context: context)
            return try repository.cleanupOldEvents(olderThanDays: 30)
        }
    }
    
    /// 清理指定应用超过30天的事件记录
    /// - Parameter appId: 应用程序ID
    /// - Returns: 删除的记录数量
    /// - Throws: 清理操作时可能抛出的错误
    func cleanupOldFirewallEvents(for appId: String) async throws -> Int {
        return try await performBackgroundTask { context in
            let repository = EventRepo(context: context)
            return try repository.deleteOldEventsByAppId(appId, olderThanDays: 30)
        }
    }
    
    /// 执行定期数据库维护任务
    /// 包括清理过期数据、优化数据库等操作
    /// - Returns: 维护任务的执行结果
    /// - Throws: 维护操作时可能抛出的错误
    @discardableResult
    nonisolated func performDatabaseMaintenance() async throws -> DBMaintenanceResult {
        // 确保在最低优先级后台执行
        return try await Task.detached(priority: .background) {
            os_log("\(self.t)👷 开始执行数据库维护任务")
            
            let startTime = Date()
            var result = DBMaintenanceResult()
            
            do {
                // 1. 清理过期的防火墙事件
                result.deletedFirewallEvents = try await self.cleanupOldFirewallEvents()

                os_log("\(self.t)🧹 已清理过期的防火墙事件，共删除 \(result.deletedFirewallEvents) 条记录")
                
                // 2. 检查数据库健康状态
                result.isDatabaseHealthy = await self.checkDatabaseHealth()

                os_log("\(self.t)🧐 已 \(result.isDatabaseHealthy ? "通过" : "未通过") 数据库健康检查")

                result.executionTime = Date().timeIntervalSince(startTime)
                result.isSuccessful = true
                
                os_log("\(self.t)✅ 数据库维护任务完成，删除了 \(result.deletedFirewallEvents) 条过期记录，耗时 \(String(format: "%.2f", result.executionTime)) 秒")
                
            } catch {
                result.error = error
                result.isSuccessful = false
                result.executionTime = Date().timeIntervalSince(startTime)
                
                os_log("\(self.t)❌ 数据库维护任务失败: \(error.localizedDescription)")
                throw error
            }
            
            return result
        }.value
    }
    
    /// 启动定期清理任务
    func startPeriodicCleanup() {
        Timer.scheduledTimer(withTimeInterval: maintenanceInterval, repeats: true) { [weak self] _ in
            guard let strongSelf = self else { return }
            Task { @MainActor in
                do {
                    let result = try await strongSelf.performDatabaseMaintenance()
                    os_log("\(strongSelf.t)🧹 定期清理任务完成: 删除 \(result.deletedFirewallEvents) 条记录")
                } catch {
                    os_log("\(strongSelf.t)⚠️ 定期清理任务失败: \(error.localizedDescription)")
                }
            }
        }
        
        os_log("\(self.t)🚀 已启动定期数据库清理任务，每\(Int(self.maintenanceInterval / 3600))小时执行一次")
    }
}

// MARK: - Migration Support

extension DBManager {
    
    /// 执行数据库迁移
    /// - Parameter version: 目标版本
    /// - Throws: 迁移时可能抛出的错误
    func migrate(to version: String) throws {
        // 这里可以添加数据库迁移逻辑
        os_log("Database migration to version \(version) completed")
    }
    
    /// 获取当前数据库版本
    /// - Returns: 当前数据库版本字符串
    func getCurrentVersion() -> String {
        // 这里可以从某个配置或元数据表中读取版本信息
        return "1.0.0"
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
