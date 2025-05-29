//
import SwiftData
import OSLog
import MagicCore
import SwiftUI

/**
 * AppSetting数据库操作仓库类
 * 
 * ## 概述
 * Repository层是数据访问层，负责封装所有与数据存储相关的操作。
 * AppSettingRepository专门负责AppSetting模型的数据访问操作。
 * 
 * ## 设计原则
 * 
 * ### 1. 单一职责 Single Responsibility
 * - 只负责AppSetting Entity的数据访问
 * - 专注于CRUD操作和数据查询
 * - 不包含业务逻辑
 * 
 * ### 2. 依赖注入 Dependency Injection
 * - 通过构造函数注入ModelContext
 * - 支持测试时注入mock context
 * - 便于单元测试
 * 
 * ### 3. 错误处理 Error Handling
 * - 所有数据库操作都抛出异常
 * - 让上层决定如何处理错误
 * - 提供详细的错误信息
 * 
 * ## 主要功能
 * - ✅ 创建新记录
 * - ✅ 根据ID查找记录
 * - ✅ 更新记录状态
 * - ✅ 删除记录
 * - ✅ 获取所有记录
 * - ✅ 权限检查逻辑
 *
 */
class AppSettingRepository {
    
    // MARK: - Properties
    
    /// 数据库上下文
    private let context: ModelContext
    
    // MARK: - Initialization
    
    /// 初始化AppSettingRepository实例
    /// - Parameter context: SwiftData模型上下文，如果为nil则使用默认容器
    init(context: ModelContext? = nil) {
        self.context = context ?? ModelContext(AppConfig.container)
    }
    
    // MARK: - CRUD Operations
    
    /// 创建新的AppSetting记录
    /// - Parameters:
    ///   - id: 应用程序ID
    ///   - allowed: 是否允许访问，默认为true
    /// - Throws: 保存数据时可能抛出的错误
    func create(_ id: String, allowed: Bool = true) throws {
        let appSetting = AppSetting(appId: id, allowed: allowed)
        context.insert(appSetting)
        try context.save()
    }
    
    /// 根据ID查找AppSetting记录
    /// - Parameter id: 应用程序ID
    /// - Returns: 找到的AppSetting实例，如果未找到则返回nil
    /// - Throws: 查询数据时可能抛出的错误
    func find(_ id: String) throws -> AppSetting? {
        let predicate = #Predicate<AppSetting> { item in
            item.appId == id
        }
        
        let items = try context.fetch(FetchDescriptor(predicate: predicate))
        return items.first
    }
    
    /// 更新AppSetting记录的允许状态
    /// - Parameters:
    ///   - id: 应用程序ID
    ///   - allowed: 新的允许状态
    /// - Throws: 保存数据时可能抛出的错误
    func updateAllowedStatus(_ id: String, allowed: Bool) throws {
        if let setting = try find(id) {
            setting.allowed = allowed
        } else {
            try create(id, allowed: allowed)
        }
        
        try context.save()
    }
    
    /// 删除AppSetting记录
    /// - Parameter id: 应用程序ID
    /// - Throws: 删除数据时可能抛出的错误
    func delete(_ id: String) throws {
        if let setting = try find(id) {
            context.delete(setting)
            try context.save()
        }
    }
    
    /// 获取所有AppSetting记录
    /// - Returns: 所有AppSetting记录的数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchAll() throws -> [AppSetting] {
        return try context.fetch(FetchDescriptor<AppSetting>())
    }
    
    /// 获取所有被拒绝访问的AppSetting记录
    /// - Returns: 所有allowed为false的AppSetting记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchDeniedApps() throws -> [AppSetting] {
        let predicate = #Predicate<AppSetting> { item in
            item.allowed == false
        }
        
        return try context.fetch(FetchDescriptor(predicate: predicate))
    }
    
    // MARK: - Permission Management
    
    /// 检查指定ID的应用是否应该被允许访问网络
    /// - Parameter id: 应用程序或进程ID
    /// - Returns: 如果允许访问返回true，否则返回false
    func shouldAllow(_ id: String) -> Bool {
        var targetId = id
        let appId = SmartApp.getApp(id)
        if let app = appId {
            // 当前进程id属于某个APP，结算到该APP头上
            targetId = app.bundleIdentifier ?? ""
        }
        
        do {
            if let setting = try find(targetId) {
                return setting.allowed
            } else {
                // 如果没有找到记录，创建一个默认允许的记录
                try create(targetId, allowed: true)
                return true
            }
        } catch {
            os_log("Error checking permission for \(targetId): \(error.localizedDescription)")
            return true // 默认允许
        }
    }
    
    /// 设置指定ID的应用为拒绝访问
    /// - Parameter id: 应用程序ID
    /// - Throws: 保存数据时可能抛出的错误
    func setDeny(_ id: String) throws {
        try updateAllowedStatus(id, allowed: false)
        self.emitDidSetDeny(id)
    }
    
    /// 设置指定ID的应用为允许访问
    /// - Parameter id: 应用程序ID
    /// - Throws: 保存数据时可能抛出的错误
    func setAllow(_ id: String) throws {
        try updateAllowedStatus(id, allowed: true)
        self.emitDidSetAllow(id)
    }
}

// MARK: - Singleton Pattern

extension AppSettingRepository {
    
    /// 共享的AppSettingRepository实例
    static let shared = AppSettingRepository()
}

// MARK: - Event Emission

extension AppSettingRepository {
    
    /// 发送允许访问事件通知
    /// - Parameter appId: 应用程序ID
    func emitDidSetAllow(_ appId: String) {
        NotificationCenter.default.post(name: .didSetAllow, object: nil, userInfo: [
            "appId": appId
        ])
    }

    /// 发送拒绝访问事件通知
    /// - Parameter appId: 应用程序ID
    func emitDidSetDeny(_ appId: String) {
        NotificationCenter.default.post(name: .didSetDeny, object: nil, userInfo: [
            "appId": appId
        ])
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }.frame(width: 700)
}
