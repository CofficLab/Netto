import Foundation
import MagicCore
import OSLog
import SwiftUI

/**
 * 应用权限服务
 * 
 * ## 概述
 * AppPermissionService是应用权限管理的核心业务逻辑服务，负责处理应用程序的核心业务规则和逻辑。
 * 它位于Repository层和UI层之间，提供了一个清晰的业务API接口。
 * 
 * ## 设计原则
 * 
 * ### 1. 业务逻辑封装 Business Logic Encapsulation
 * - 将复杂的业务规则封装在Service中
 * - 提供简洁、易用的API接口
 * - 隐藏底层数据访问的复杂性
 * 
 * ### 2. 单一职责 Single Responsibility
 * - 专注于应用权限管理这一个业务领域
 * - 避免与其他Service的紧耦合
 * - 保持方法的单一职责
 * 
 * ### 3. 依赖注入 Dependency Injection
 * - 通过构造函数注入DatabaseManager依赖
 * - 支持测试时注入mock对象
 * - 便于单元测试和集成测试
 * 
 * ### 4. 事务管理 Transaction Management
 * - 在Service层管理数据库事务
 * - 确保业务操作的原子性
 * - 处理跨多个Repository的操作
 * 
 * ## 主要职责
 * - 🔐 应用权限的业务逻辑处理
 * - 📊 权限统计和分析
 * - 🔄 批量权限操作
 * - ✅ 数据验证和清理
 * - 📝 业务日志记录
 * 
 * ## 核心功能模块
 * 
 * ### 1. 权限管理 Permission Management
 * - shouldAllow(_:): 检查应用权限状态
 * - allow(_:): 设置应用为允许访问
 * - deny(_:): 设置应用为拒绝访问
 * - togglePermission(_:): 切换应用权限状态
 * 
 * ### 2. 批量操作 Batch Operations
 * - setBatchPermissions(_:allowed:): 批量设置多个应用的权限
 * - resetAllPermissions(): 重置所有权限为默认状态
 * 
 * ### 3. 查询统计 Query & Statistics
 * - getDeniedApps(): 获取被拒绝的应用列表
 * - getAllowedApps(): 获取被允许的应用列表
 * - getPermissionStats(): 获取权限统计信息
 * 
 * ### 4. 数据维护 Data Maintenance
 * - isValidAppId(_:): 验证应用ID的有效性
 * - cleanupInvalidPermissions(): 清理无效的权限记录
 * 
 * ## 使用示例
 * 
 * ### 基本权限操作
 * ```swift
 * let permissionService = AppPermissionService.shared
 * 
 * // 检查权限
 * if permissionService.shouldAllow("com.example.app") {
 *     print("App is allowed")
 * }
 * 
 * // 设置权限
 * try permissionService.allow("com.example.app")
 * try permissionService.deny("com.malicious.app")
 * 
 * // 切换权限状态
 * try permissionService.togglePermission("com.example.app")
 * ```
 * 
 * ### 批量操作
 * ```swift
 * // 批量拒绝多个应用
 * let suspiciousApps = ["com.app1", "com.app2", "com.app3"]
 * try permissionService.setBatchPermissions(suspiciousApps, allowed: false)
 * 
 * // 重置所有权限为默认状态
 * try permissionService.resetAllPermissions()
 * ```
 * 
 * ### 统计查询
 * ```swift
 * // 获取权限统计
 * let stats = try permissionService.getPermissionStats()
 * print("允许: \(stats.allowed), 拒绝: \(stats.denied), 总计: \(stats.total)")
 * 
 * // 获取被拒绝的应用列表
 * let deniedApps = try permissionService.getDeniedApps()
 * print("被拒绝的应用: \(deniedApps)")
 * ```
 * 
 * ### 数据维护
 * ```swift
 * // 清理无效的权限记录
 * try permissionService.cleanupInvalidPermissions()
 * 
 * // 验证应用ID
 * if permissionService.isValidAppId("com.example.app") {
 *     // 处理有效的应用ID
 * }
 * ```
 * 
 * ## 最佳实践
 * 
 * ### 1. 业务逻辑封装
 * - 将复杂的业务规则封装在Service方法中
 * - 避免在UI层直接调用Repository
 * - 提供语义化的业务方法名
 * 
 * ### 2. 错误处理
 * - 将技术异常转换为业务异常
 * - 提供有意义的错误信息
 * - 记录详细的业务日志
 * 
 * ### 3. 事务管理
 * - 对于复杂的业务操作使用事务
 * - 确保数据操作的原子性
 * - 处理并发访问的冲突
 * 
 * ### 4. 缓存策略
 * - 缓存频繁访问的权限数据
 * - 实现合适的缓存失效策略
 * - 平衡性能和数据一致性
 * 
 * ### 5. 异步操作
 * - 对于耗时的业务操作使用异步处理
 * - 避免阻塞UI线程
 * - 提供适当的进度反馈
 * 
 * ## 测试策略
 * 
 * ### 1. 单元测试
 * - 测试每个业务方法的逻辑正确性
 * - 使用mock对象隔离依赖
 * - 覆盖各种边界条件和异常情况
 * 
 * ### 2. 集成测试
 * - 测试Service与Repository的集成
 * - 验证完整的业务流程
 * - 测试事务的正确性
 * 
 * ### 3. 性能测试
 * - 测试批量操作的性能
 * - 验证缓存机制的有效性
 * - 监控内存使用情况
 * 
 * ## 注意事项
 * 
 * 1. **避免Service之间的循环依赖**
 *    - 设计清晰的Service依赖关系
 *    - 使用事件驱动架构解耦Service
 * 
 * 2. **保持Service的轻量级**
 *    - 避免在Service中包含过多的状态
 *    - 优先使用无状态的Service设计
 * 
 * 3. **业务规则的一致性**
 *    - 确保相同的业务规则在不同地方的一致性
 *    - 避免业务逻辑的重复实现
 * 
 * 4. **日志和监控**
 *    - 记录关键业务操作的日志
 *    - 监控Service的性能指标
 *    - 实现适当的错误报告机制
 */
@MainActor
class AppPermissionService: SuperLog {
    nonisolated static let emoji = "💁"
    
    // MARK: - Properties

    /// 数据库管理器
    private let databaseManager: DatabaseManager

    /// AppSetting仓库
    private var repository: AppSettingRepository {
        return databaseManager.appSettingRepository
    }

    // MARK: - Singleton

    /// 共享的应用权限服务实例
    static let shared = AppPermissionService()

    // MARK: - Initialization

    /// 初始化应用权限服务
    /// - Parameter databaseManager: 数据库管理器，如果为nil则使用共享实例
    private init(databaseManager: DatabaseManager? = nil) {
        self.databaseManager = databaseManager ?? DatabaseManager.shared
    }

    // MARK: - Permission Management

    /// 检查指定ID的应用是否应该被允许访问网络
    /// - Parameter id: 应用程序或进程ID
    /// - Returns: 如果允许访问返回true，否则返回false
    func shouldAllow(_ id: String) -> Bool {
        return repository.shouldAllow(id)
    }

    /// 设置指定ID的应用为允许访问
    /// - Parameter id: 应用程序ID
    /// - Throws: 保存数据时可能抛出的错误
    func allow(_ id: String) throws {
        try repository.setAllow(id)
        os_log("App \(id) has been allowed network access")
    }

    /// 设置指定ID的应用为拒绝访问
    /// - Parameter id: 应用程序ID
    /// - Throws: 保存数据时可能抛出的错误
    func deny(_ id: String) throws {
        try repository.setDeny(id)
        os_log("\(self.t)💾 App \(id) has been denied network access")
    }

    /// 切换应用的访问权限状态
    /// - Parameter id: 应用程序ID
    /// - Throws: 保存数据时可能抛出的错误
    func togglePermission(_ id: String) throws {
        let currentStatus = shouldAllow(id)
        if currentStatus {
            try deny(id)
        } else {
            try allow(id)
        }
    }

    // MARK: - Batch Operations

    /// 批量设置多个应用的权限
    /// - Parameters:
    ///   - appIds: 应用程序ID数组
    ///   - allowed: 是否允许访问
    /// - Throws: 保存数据时可能抛出的错误
    func setBatchPermissions(_ appIds: [String], allowed: Bool) throws {
        for appId in appIds {
            if allowed {
                try repository.setAllow(appId)
            } else {
                try repository.setDeny(appId)
            }
        }

        let action = allowed ? "allowed" : "denied"
        os_log("Batch operation: \(appIds.count) apps have been \(action) network access")
    }

    /// 重置所有应用权限为默认状态（允许）
    /// - Throws: 保存数据时可能抛出的错误
    func resetAllPermissions() throws {
        let allSettings = try repository.fetchAll()

        for setting in allSettings {
            try repository.setAllow(setting.appId)
        }

        os_log("All app permissions have been reset to default (allowed)")
    }

    // MARK: - Query Operations

    /// 获取所有被拒绝访问的应用ID列表
    /// - Returns: 被拒绝的应用ID数组
    /// - Throws: 查询数据时可能抛出的错误
    func getDeniedApps() throws -> [String] {
        let allSettings = try repository.fetchAll()
        return allSettings.filter { !$0.allowed }.map { $0.appId }
    }

    /// 获取所有被允许访问的应用ID列表
    /// - Returns: 被允许的应用ID数组
    /// - Throws: 查询数据时可能抛出的错误
    func getAllowedApps() throws -> [String] {
        let allSettings = try repository.fetchAll()
        return allSettings.filter { $0.allowed }.map { $0.appId }
    }

    /// 获取权限统计信息
    /// - Returns: 包含允许和拒绝数量的统计信息
    /// - Throws: 查询数据时可能抛出的错误
    func getPermissionStats() throws -> (allowed: Int, denied: Int, total: Int) {
        let allSettings = try repository.fetchAll()
        let allowedCount = allSettings.filter { $0.allowed }.count
        let deniedCount = allSettings.filter { !$0.allowed }.count

        return (allowed: allowedCount, denied: deniedCount, total: allSettings.count)
    }

    // MARK: - Validation

    /// 验证应用ID是否有效
    /// - Parameter id: 应用程序ID
    /// - Returns: 如果ID有效返回true，否则返回false
    func isValidAppId(_ id: String) -> Bool {
        return !id.isEmpty && !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 清理无效的权限记录
    /// - Throws: 删除数据时可能抛出的错误
    func cleanupInvalidPermissions() throws {
        let allSettings = try repository.fetchAll()
        var deletedCount = 0

        for setting in allSettings {
            if !isValidAppId(setting.appId) {
                try repository.delete(setting.appId)
                deletedCount += 1
            }
        }

        if deletedCount > 0 {
            os_log("Cleaned up \(deletedCount) invalid permission records")
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
