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
class EventRepo: SuperLog, ObservableObject {
    // MARK: - Properties
    
    nonisolated static let emoji = "🏠"

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
    
    /// 删除指定应用ID超过指定天数的事件记录
    /// - Parameters:
    ///   - appId: 应用程序ID
    ///   - days: 保留天数，超过此天数的记录将被删除
    /// - Returns: 删除的记录数量
    /// - Throws: 删除数据时可能抛出的错误
    func deleteOldEventsByAppId(_ appId: String, olderThanDays days: Int) throws -> Int {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let predicate = #Predicate<FirewallEventModel> { item in
            item.sourceAppIdentifier == appId && item.time < cutoffDate
        }
        
        let events = try context.fetch(FetchDescriptor(predicate: predicate))
        let deletedCount = events.count
        
        for event in events {
            context.delete(event)
        }
        
        if deletedCount > 0 {
            try context.save()
            os_log("\(self.t)已删除应用 \(appId) 超过 \(days) 天的 \(deletedCount) 条事件记录")
        }
        
        return deletedCount
    }
    
    /// 批量清理所有应用超过指定天数的事件记录
    /// - Parameter days: 保留天数，超过此天数的记录将被删除
    /// - Returns: 删除的总记录数量
    /// - Throws: 删除数据时可能抛出的错误
    func cleanupOldEvents(olderThanDays days: Int) throws -> Int {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let predicate = #Predicate<FirewallEventModel> { item in
            item.time < cutoffDate
        }
        
        let events = try context.fetch(FetchDescriptor(predicate: predicate))
        let deletedCount = events.count
        
        for event in events {
            context.delete(event)
        }
        
        if deletedCount > 0 {
            try context.save()
            os_log("\(self.t)🧹 已清理超过 \(days) 天的 \(deletedCount) 条事件记录")
        }
        
        return deletedCount
    }
    
    /// 获取所有应用的唯一ID列表
    /// - Returns: 应用ID数组
    /// - Throws: 查询数据时可能抛出的错误
    func getAllUniqueAppIds() throws -> [String] {
        let events = try context.fetch(FetchDescriptor<FirewallEventModel>())
        let uniqueAppIds = Set(events.compactMap { $0.sourceAppIdentifier })
        return Array(uniqueAppIds)
    }

    /// 获取所有FirewallEvent记录
    /// - Returns: 所有FirewallEventModel记录的数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchAll() throws -> [FirewallEventModel] {
        let descriptor = FetchDescriptor<FirewallEventModel>(
            sortBy: [SortDescriptor(\.time, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    /// 分页获取所有FirewallEvent记录
    /// - Parameters:
    ///   - page: 页码（从0开始）
    ///   - pageSize: 每页记录数
    /// - Returns: 分页后的FirewallEventModel记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchAllPaginated(
        page: Int,
        pageSize: Int
    ) throws -> [FirewallEventModel] {
        os_log("\(self.t)分页获取所有FirewallEvent记录, 页码: \(page), 每页: \(pageSize)")
        
        // 创建查询描述符
        var descriptor = FetchDescriptor<FirewallEventModel>(
            sortBy: [SortDescriptor(\.time, order: .reverse)]
        )
        
        // 设置分页参数
        descriptor.fetchOffset = page * pageSize
        descriptor.fetchLimit = pageSize
        
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
        os_log("\(self.t)根据应用ID查找FirewallEvent记录 -> \(appId)")
        let predicate = #Predicate<FirewallEventModel> { item in
            item.sourceAppIdentifier == appId
        }

        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    /// 根据应用ID分页查找FirewallEvent记录
    /// - Parameters:
    ///   - appId: 应用程序ID
    ///   - page: 页码（从0开始）
    ///   - pageSize: 每页记录数
    ///   - statusFilter: 状态筛选（可选）
    ///   - directionFilter: 方向筛选（可选）
    /// - Returns: 分页后的FirewallEventModel记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchByAppIdPaginated(
        _ appId: String,
        page: Int,
        pageSize: Int,
        statusFilter: FirewallEvent.Status? = nil,
        directionFilter: NETrafficDirection? = nil
    ) throws -> [FirewallEventModel] {
        os_log("\(self.t)根据应用ID分页查找FirewallEvent记录 -> \(appId), 页码: \(page), 每页: \(pageSize)")
        
        // 构建查询条件
        var predicates: [Predicate<FirewallEventModel>] = [
            #Predicate<FirewallEventModel> { item in item.sourceAppIdentifier == appId }
        ]
        
        // 添加状态筛选
        if let statusFilter = statusFilter {
            let statusValue = statusFilter == .allowed ? 0 : 1
            predicates.append(#Predicate<FirewallEventModel> { item in item.statusRawValue == statusValue })
        }
        
        // 添加方向筛选
        if let directionFilter = directionFilter {
            let directionValue = directionFilter.rawValue
            predicates.append(#Predicate<FirewallEventModel> { item in item.directionRawValue == directionValue })
        }
        
        // 组合所有条件
        let combinedPredicate = predicates.reduce(into: predicates[0]) { result, predicate in
            result = #Predicate<FirewallEventModel> { item in
                result.evaluate(item) && predicate.evaluate(item)
            }
        }
        
        // 创建查询描述符
        var descriptor = FetchDescriptor<FirewallEventModel>(
            predicate: combinedPredicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        
        // 设置分页参数
        descriptor.fetchOffset = page * pageSize
        descriptor.fetchLimit = pageSize
        
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
    
    /// 获取指定应用的事件总数（带筛选）
    /// - Parameters:
    ///   - appId: 应用程序ID
    ///   - statusFilter: 状态筛选（可选）
    ///   - directionFilter: 方向筛选（可选）
    /// - Returns: 符合条件的事件总数
    /// - Throws: 查询数据时可能抛出的错误
    func getEventCountByAppIdFiltered(
        _ appId: String,
        statusFilter: FirewallEvent.Status? = nil,
        directionFilter: NETrafficDirection? = nil
    ) throws -> Int {
        // 构建查询条件
        var predicates: [Predicate<FirewallEventModel>] = [
            #Predicate<FirewallEventModel> { item in item.sourceAppIdentifier == appId }
        ]
        
        // 添加状态筛选
        if let statusFilter = statusFilter {
            let statusValue = statusFilter == .allowed ? 0 : 1
            predicates.append(#Predicate<FirewallEventModel> { item in item.statusRawValue == statusValue })
        }
        
        // 添加方向筛选
        if let directionFilter = directionFilter {
            let directionValue = directionFilter.rawValue
            predicates.append(#Predicate<FirewallEventModel> { item in item.directionRawValue == directionValue })
        }
        
        // 组合所有条件
        let combinedPredicate = predicates.reduce(into: predicates[0]) { result, predicate in
            result = #Predicate<FirewallEventModel> { item in
                result.evaluate(item) && predicate.evaluate(item)
            }
        }
        
        let descriptor = FetchDescriptor(predicate: combinedPredicate)
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

extension EventRepo {
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

#Preview("App") {
    RootView {
        ContentView()
    }
    .frame(width: 700)
    .frame(height: 800)
}

#Preview("防火墙事件视图") {
    RootView {
        DBEventView()
    }
    .frame(width: 600, height: 700)
}
