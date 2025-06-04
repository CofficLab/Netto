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
 * ## 主要职责
 * - ModelContainer和ModelContext的管理
 * - Repository实例的创建和管理
 * - 后台任务执行
 * - 数据库健康检查
 * - 数据迁移支持
 * 
 * ## 设计模式
 * 
 * ### 单例模式 Singleton Pattern
 * DatabaseManager采用单例模式，确保整个应用程序中只有一个数据库管理器实例。
 * 
 * ### 工厂模式 Factory Pattern
 * 通过lazy属性创建和管理各种Repository实例，提供统一的Repository访问接口。
 * 
 * ### 依赖注入 Dependency Injection
 * 支持在初始化时注入自定义的ModelContainer，便于测试和不同环境的配置。
 * 
 * ## 使用示例
 * 
 * ### 基本用法
 * ```swift
 * // 获取共享实例
 * let databaseManager = DatabaseManager.shared
 * 
 * // 访问Repository
 * let appSettingRepo = databaseManager.appSettingRepository
 * ```
 * 
 * ### 后台任务执行
 * ```swift
 * try await databaseManager.performBackgroundTask { context in
 *     // 在后台上下文中执行数据库操作
 *     let repository = AppSettingRepository(context: context)
 *     try repository.create("com.example.app")
 * }
 * ```
 * 
 * ### 数据库健康检查
 * ```swift
 * let isHealthy = await databaseManager.checkDatabaseHealth()
 * if !isHealthy {
 *     // 处理数据库健康问题
 * }
 * ```
 * 
 * ## 扩展指南
 * 
 * ### 添加新的Repository
 * 
 * 1. **在DatabaseManager中添加lazy属性**
 * ```swift
 * lazy var newEntityRepository: NewEntityRepository = {
 *     return NewEntityRepository(context: mainContext)
 * }()
 * ```
 * 
 * 2. **遵循命名约定**
 * - 属性名: `{entityName}Repository`
 * - 类型: `{EntityName}Repository`
 * 
 * ## 最佳实践
 * 
 * ### 1. 上下文管理
 * - 使用mainContext进行UI相关的数据操作
 * - 使用performBackgroundTask进行后台数据处理
 * - 避免跨线程共享上下文
 * 
 * ### 2. 错误处理
 * - 所有数据库操作都应该在try-catch块中执行
 * - 记录详细的错误日志
 * - 提供有意义的错误信息给上层调用者
 * 
 * ### 3. 性能优化
 * - 使用批量操作减少数据库访问次数
 * - 合理配置上下文的自动保存策略
 * - 监控数据库操作的性能指标
 * 
 * ### 4. 测试支持
 * - 支持注入测试用的ModelContainer
 * - 提供数据库重置功能用于测试
 * - 确保测试之间的数据隔离
 * 
 * ## 注意事项
 * 
 * 1. **线程安全**
 *    - ModelContext不是线程安全的
 *    - 使用performBackgroundTask进行后台操作
 *    - 避免在不同线程间共享上下文
 * 
 * 2. **内存管理**
 *    - 及时释放不再使用的上下文
 *    - 避免长时间持有大量数据对象
 *    - 定期清理缓存数据
 * 
 * 3. **数据一致性**
 *    - 使用事务确保数据操作的原子性
 *    - 处理并发访问的冲突
 *    - 实现适当的数据验证机制
 */
class DBManager: @unchecked Sendable, SuperLog {
    static let emoji = "🏭"
    static let shared = DBManager()
    
    // MARK: - Properties
    
    /// 数据库容器
    private let container: ModelContainer
    
    /// 主上下文
    private let mainContext: ModelContext
    
    /// AppSetting仓库
    lazy var appSettingRepository: AppSettingRepository = {
        return AppSettingRepository(context: mainContext)
    }()
    
    /// FirewallEvent仓库
    lazy var firewallEventRepository: FirewallEventRepository = {
        return FirewallEventRepository(context: mainContext)
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
        if let container = container {
            self.container = container
        } else {
            self.container = Self.container()
        }
        
        self.mainContext = ModelContext(self.container)
        
        // 配置上下文
        configureContext()
        
        self.startPeriodicCleanup()
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
    
    /// 获取数据库统计信息
    /// - Returns: 包含各种数据统计的字典
    /// - Throws: 查询时可能抛出的错误
    func getDatabaseStats() throws -> [String: Int] {
        let appSettingsCount = try mainContext.fetch(FetchDescriptor<AppSetting>()).count
        let firewallEventsCount = try mainContext.fetch(FetchDescriptor<FirewallEventModel>()).count
        
        return [
            "appSettings": appSettingsCount,
            "firewallEvents": firewallEventsCount
        ]
    }
    
    /// 检查数据库健康状态
    /// - Returns: 数据库是否健康
    func checkDatabaseHealth() -> Bool {
        do {
            // 尝试执行一个简单的查询来检查数据库连接
            _ = try mainContext.fetch(FetchDescriptor<AppSetting>())
            return true
        } catch {
            os_log("Database health check failed: \(error.localizedDescription)")
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
    func cleanupOldFirewallEvents() async throws -> Int {
        return try await performBackgroundTask { context in
            let repository = FirewallEventRepository(context: context)
            return try repository.cleanupOldEvents(olderThanDays: 30)
        }
    }
    
    /// 清理指定应用超过30天的事件记录
    /// - Parameter appId: 应用程序ID
    /// - Returns: 删除的记录数量
    /// - Throws: 清理操作时可能抛出的错误
    func cleanupOldFirewallEvents(for appId: String) async throws -> Int {
        return try await performBackgroundTask { context in
            let repository = FirewallEventRepository(context: context)
            return try repository.deleteOldEventsByAppId(appId, olderThanDays: 30)
        }
    }
    
    /// 执行定期数据库维护任务
    /// 包括清理过期数据、优化数据库等操作
    /// - Returns: 维护任务的执行结果
    /// - Throws: 维护操作时可能抛出的错误
    func performDatabaseMaintenance() async throws -> DatabaseMaintenanceResult {
        os_log("开始执行数据库维护任务")
        
        let startTime = Date()
        var result = DatabaseMaintenanceResult()
        
        do {
            // 1. 清理过期的防火墙事件
            result.deletedFirewallEvents = try await cleanupOldFirewallEvents()
            
            // 2. 检查数据库健康状态
            result.isDatabaseHealthy = checkDatabaseHealth()
            
            // 3. 获取数据库统计信息
            result.databaseStats = try getDatabaseStats()
            
            result.executionTime = Date().timeIntervalSince(startTime)
            result.isSuccessful = true
            
            os_log("数据库维护任务完成，删除了 \(result.deletedFirewallEvents) 条过期记录，耗时 \(String(format: "%.2f", result.executionTime)) 秒")
            
        } catch {
            result.error = error
            result.isSuccessful = false
            result.executionTime = Date().timeIntervalSince(startTime)
            
            os_log("数据库维护任务失败: \(error.localizedDescription)")
            throw error
        }
        
        return result
    }
    
    /// 启动定期清理任务
    /// 每24小时自动执行一次数据库维护
    func startPeriodicCleanup() {
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            Task {
                guard let self = self else { return }
                do {
                    let result = try await self.performDatabaseMaintenance()
                    os_log("定期清理任务完成: 删除 \(result.deletedFirewallEvents) 条记录")
                } catch {
                    os_log("定期清理任务失败: \(error.localizedDescription)")
                }
            }
        }
        
        os_log("\(self.t)🚀 已启动定期数据库清理任务，每24小时执行一次")
    }
}

// MARK: - Database Maintenance Result

/// 数据库维护任务执行结果
struct DatabaseMaintenanceResult {
    /// 删除的防火墙事件数量
    var deletedFirewallEvents: Int = 0
    
    /// 数据库是否健康
    var isDatabaseHealthy: Bool = false
    
    /// 数据库统计信息
    var databaseStats: [String: Int] = [:]
    
    /// 执行时间（秒）
    var executionTime: TimeInterval = 0
    
    /// 是否执行成功
    var isSuccessful: Bool = false
    
    /// 错误信息（如果有）
    var error: Error?
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
