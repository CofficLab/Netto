import Foundation
import MagicCore
import OSLog
import SwiftUI

/**
 * 应用权限服务
 * 
 * ## 概述
 * PermissionService是应用权限管理的核心业务逻辑服务，负责处理应用程序的核心业务规则和逻辑。
 * 它位于Repository层和UI层之间，提供了一个清晰的业务API接口。
 * 
 * ## 主要职责
 * - 🔐 应用权限的业务逻辑处理
 * - 📊 权限统计和分析
 * - 🔄 批量权限操作
 * - ✅ 数据验证和清理
 * - 📝 业务日志记录
 */
class PermissionService: SuperLog {
    nonisolated static let emoji = "💁"
    
    // MARK: - Properties

    /// AppSetting仓库
    private var repo: AppSettingRepo

    // MARK: - Initialization

    init(repo: AppSettingRepo) {
        self.repo = repo
    }

    // MARK: - Permission Management

    /// 检查指定ID的应用是否应该被允许访问网络
    /// - Parameter id: 应用程序或进程ID
    /// - Returns: 如果允许访问返回true，否则返回false
    func shouldAllow(_ id: String) async -> Bool {
        return await repo.shouldAllow(id)
    }

    /// 设置指定ID的应用为允许访问
    /// - Parameter id: 应用程序ID
    /// - Throws: 保存数据时可能抛出的错误
    func allow(_ id: String) async throws {
        try await repo.setAllow(id)
        os_log("App \(id) has been allowed network access")
    }

    /// 设置指定ID的应用为拒绝访问
    /// - Parameter id: 应用程序ID
    /// - Throws: 保存数据时可能抛出的错误
    func deny(_ id: String) async throws {
        try await repo.setDeny(id)
        os_log("\(self.t)💾 App \(id) has been denied network access")
    }

    /// 切换应用的访问权限状态
    /// - Parameter id: 应用程序ID
    /// - Throws: 保存数据时可能抛出的错误
    func togglePermission(_ id: String) async throws {
        let currentStatus = await shouldAllow(id)
        if currentStatus {
            try await deny(id)
        } else {
            try await allow(id)
        }
    }

    // MARK: - Batch Operations

    /// 批量设置多个应用的权限
    /// - Parameters:
    ///   - appIds: 应用程序ID数组
    ///   - allowed: 是否允许访问
    /// - Throws: 保存数据时可能抛出的错误
    func setBatchPermissions(_ appIds: [String], allowed: Bool) async throws {
        for appId in appIds {
            if allowed {
                try await repo.setAllow(appId)
            } else {
                try await repo.setDeny(appId)
            }
        }

        let action = allowed ? "allowed" : "denied"
        os_log("Batch operation: \(appIds.count) apps have been \(action) network access")
    }

    /// 重置所有应用权限为默认状态（允许）
    /// - Throws: 保存数据时可能抛出的错误
    func resetAllPermissions() async throws {
        let allSettings = try await repo.fetchAll()

        for setting in allSettings {
            try await repo.setAllow(setting.appId)
        }

        os_log("All app permissions have been reset to default (allowed)")
    }

    // MARK: - Query Operations

    /// 获取所有被拒绝访问的应用ID列表
    /// - Returns: 被拒绝的应用ID数组
    /// - Throws: 查询数据时可能抛出的错误
    func getDeniedApps() async throws -> [String] {
        let allSettings = try await repo.fetchAll()
        return allSettings.filter { !$0.allowed }.map { $0.appId }
    }

    /// 获取所有被允许访问的应用ID列表
    /// - Returns: 被允许的应用ID数组
    /// - Throws: 查询数据时可能抛出的错误
    func getAllowedApps() async throws -> [String] {
        let allSettings = try await repo.fetchAll()
        return allSettings.filter { $0.allowed }.map { $0.appId }
    }

    /// 获取权限统计信息
    /// - Returns: 包含允许和拒绝数量的统计信息
    /// - Throws: 查询数据时可能抛出的错误
    func getPermissionStats() async throws -> (allowed: Int, denied: Int, total: Int) {
        let allSettings = try await repo.fetchAll()
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
    func cleanupInvalidPermissions() async throws {
        let allSettings = try await repo.fetchAll()
        var deletedCount = 0

        for setting in allSettings {
            if !isValidAppId(setting.appId) {
                try await repo.delete(setting.appId)
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
