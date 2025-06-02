import Foundation
import MagicCore
import OSLog
import SwiftData
import SwiftUI
import NetworkExtension

/**
 * FirewallEvent数据库操作仓库类
 *
 * ## 概述
 * Repository层是数据访问层，负责封装所有与数据存储相关的操作。
 * FirewallEventRepository专门负责FirewallEventModel模型的数据访问操作。
 *
 * ## 设计原则
 *
 * ### 1. 单一职责 Single Responsibility
 * - 只负责FirewallEventModel Entity的数据访问
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
 * - ✅ 根据应用ID查找记录
 * - ✅ 删除记录
 * - ✅ 获取所有记录
 * - ✅ 按时间范围查询
 * - ✅ 按状态查询
 * - ✅ 按应用ID查询
 *
 */
class FirewallEventRepository {
    // MARK: - Properties

    /// 数据库上下文
    private let context: ModelContext

    // MARK: - Initialization

    /// 初始化FirewallEventRepository实例
    /// - Parameter context: SwiftData模型上下文
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - CRUD Operations

    /// 创建新的FirewallEvent记录
    /// - Parameter event: FirewallEvent结构体实例
    /// - Throws: 保存数据时可能抛出的错误
    func create(_ event: FirewallEvent) throws {
        let eventModel = FirewallEventModel.from(event)
        context.insert(eventModel)
        try context.save()
    }
    
    /// 批量创建FirewallEvent记录
    /// - Parameter events: FirewallEvent结构体实例数组
    /// - Throws: 保存数据时可能抛出的错误
    func createBatch(_ events: [FirewallEvent]) throws {
        for event in events {
            let eventModel = FirewallEventModel.from(event)
            context.insert(eventModel)
        }
        try context.save()
    }

    /// 根据ID查找FirewallEvent记录
    /// - Parameter id: 事件ID
    /// - Returns: 找到的FirewallEventModel实例，如果未找到则返回nil
    /// - Throws: 查询数据时可能抛出的错误
    func find(_ id: String) throws -> FirewallEventModel? {
        let predicate = #Predicate<FirewallEventModel> { item in
            item.id == id
        }

        let items = try context.fetch(FetchDescriptor(predicate: predicate))
        return items.first
    }

    /// 删除FirewallEvent记录
    /// - Parameter id: 事件ID
    /// - Throws: 删除数据时可能抛出的错误
    func delete(_ id: String) throws {
        if let event = try find(id) {
            context.delete(event)
            try context.save()
        }
    }
    
    /// 删除指定应用的所有事件记录
    /// - Parameter appId: 应用程序ID
    /// - Throws: 删除数据时可能抛出的错误
    func deleteByAppId(_ appId: String) throws {
        let events = try fetchByAppId(appId)
        for event in events {
            context.delete(event)
        }
        try context.save()
    }
    
    /// 删除指定时间之前的所有事件记录
    /// - Parameter date: 截止日期
    /// - Throws: 删除数据时可能抛出的错误
    func deleteBefore(_ date: Date) throws {
        let predicate = #Predicate<FirewallEventModel> { item in
            item.time < date
        }
        
        let events = try context.fetch(FetchDescriptor(predicate: predicate))
        for event in events {
            context.delete(event)
        }
        try context.save()
    }

    /// 获取所有FirewallEvent记录
    /// - Returns: 所有FirewallEventModel记录的数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchAll() throws -> [FirewallEventModel] {
        let descriptor = FetchDescriptor<FirewallEventModel>(
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    /// 获取指定数量的最新FirewallEvent记录
    /// - Parameter limit: 限制数量
    /// - Returns: 最新的FirewallEventModel记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchLatest(limit: Int = 100) throws -> [FirewallEventModel] {
        var descriptor = FetchDescriptor<FirewallEventModel>(
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    // MARK: - Query Operations

    /// 根据应用ID查找FirewallEvent记录
    /// - Parameter appId: 应用程序ID
    /// - Returns: 该应用的所有FirewallEventModel记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchByAppId(_ appId: String) throws -> [FirewallEventModel] {
        let predicate = #Predicate<FirewallEventModel> { item in
            item.sourceAppIdentifier == appId
        }

        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// 根据状态查找FirewallEvent记录
    /// - Parameter status: 防火墙状态
    /// - Returns: 指定状态的所有FirewallEventModel记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchByStatus(_ status: FirewallEvent.Status) throws -> [FirewallEventModel] {
        let statusValue = status == .allowed ? 0 : 1
        let predicate = #Predicate<FirewallEventModel> { item in
            item.statusRawValue == statusValue
        }

        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    /// 根据网络流量方向查找FirewallEvent记录
    /// - Parameter direction: 网络流量方向
    /// - Returns: 指定方向的所有FirewallEventModel记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchByDirection(_ direction: NETrafficDirection) throws -> [FirewallEventModel] {
        let directionValue = direction.rawValue
        let predicate = #Predicate<FirewallEventModel> { item in
            item.directionRawValue == directionValue
        }

        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// 根据时间范围查找FirewallEvent记录
    /// - Parameters:
    ///   - startDate: 开始时间
    ///   - endDate: 结束时间
    /// - Returns: 指定时间范围内的所有FirewallEventModel记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchByTimeRange(from startDate: Date, to endDate: Date) throws -> [FirewallEventModel] {
        let predicate = #Predicate<FirewallEventModel> { item in
            item.time >= startDate && item.time <= endDate
        }

        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    /// 根据地址查找FirewallEvent记录
    /// - Parameter address: 目标地址
    /// - Returns: 指定地址的所有FirewallEventModel记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchByAddress(_ address: String) throws -> [FirewallEventModel] {
        let predicate = #Predicate<FirewallEventModel> { item in
            item.address == address
        }

        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    /// 复合查询：根据应用ID和状态查找记录
    /// - Parameters:
    ///   - appId: 应用程序ID
    ///   - status: 防火墙状态
    /// - Returns: 符合条件的FirewallEventModel记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchByAppIdAndStatus(_ appId: String, status: FirewallEvent.Status) throws -> [FirewallEventModel] {
        let statusValue = status == .allowed ? 0 : 1
        let predicate = #Predicate<FirewallEventModel> { item in
            item.sourceAppIdentifier == appId && item.statusRawValue == statusValue
        }

        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Statistics

    /// 获取事件总数
    /// - Returns: 事件总数
    /// - Throws: 查询数据时可能抛出的错误
    func getEventCount() throws -> Int {
        let descriptor = FetchDescriptor<FirewallEventModel>()
        return try context.fetchCount(descriptor)
    }
    
    /// 获取指定应用的事件总数
    /// - Parameter appId: 应用程序ID
    /// - Returns: 该应用的事件总数
    /// - Throws: 查询数据时可能抛出的错误
    func getEventCountByAppId(_ appId: String) throws -> Int {
        let predicate = #Predicate<FirewallEventModel> { item in
            item.sourceAppIdentifier == appId
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try context.fetchCount(descriptor)
    }
    
    /// 获取被阻止的事件总数
    /// - Returns: 被阻止的事件总数
    /// - Throws: 查询数据时可能抛出的错误
    func getRejectedEventCount() throws -> Int {
        let predicate = #Predicate<FirewallEventModel> { item in
            item.statusRawValue == 1
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try context.fetchCount(descriptor)
    }
    
    /// 获取被允许的事件总数
    /// - Returns: 被允许的事件总数
    /// - Throws: 查询数据时可能抛出的错误
    func getAllowedEventCount() throws -> Int {
        let predicate = #Predicate<FirewallEventModel> { item in
            item.statusRawValue == 0
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try context.fetchCount(descriptor)
    }
}

// MARK: - Event Emission

extension FirewallEventRepository {
    /// 发送新事件创建通知
    /// - Parameter event: 新创建的事件
    func emitEventCreated(_ event: FirewallEventModel) {
        NotificationCenter.default.post(name: .firewallEventCreated, object: nil, userInfo: [
            "event": event,
        ])
    }
    
    /// 发送事件删除通知
    /// - Parameter eventId: 被删除的事件ID
    func emitEventDeleted(_ eventId: String) {
        NotificationCenter.default.post(name: .firewallEventDeleted, object: nil, userInfo: [
            "eventId": eventId,
        ])
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let firewallEventCreated = Notification.Name("firewallEventCreated")
    static let firewallEventDeleted = Notification.Name("firewallEventDeleted")
}

#Preview("FirewallEvent Repository") {
    RootView {
        ContentView()
    }
    .frame(width: 700)
    .frame(height: 800)
}