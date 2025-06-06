import Foundation
import MagicCore
import OSLog
import SwiftUI
import NetworkExtension

/**
 * 防火墙事件服务
 * 
 * ## 概述
 * EventService是防火墙事件管理的核心业务逻辑服务，负责处理防火墙事件的核心业务规则和逻辑。
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
 * - 专注于防火墙事件管理这一个业务领域
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
 * - 🔥 防火墙事件的业务逻辑处理
 * - 📊 事件统计和分析
 * - 🔄 批量事件操作
 * - ✅ 数据验证和清理
 * - 📝 业务日志记录
 * 
 * ## 核心功能模块
 * 
 * ### 1. 事件管理 Event Management
 * - recordEvent(_:): 记录新的防火墙事件
 * - getEventById(_:): 根据ID获取事件
 * - deleteEvent(_:): 删除指定事件
 * 
 * ### 2. 批量操作 Batch Operations
 * - recordEvents(_:): 批量记录多个事件
 * - deleteEventsByAppId(_:): 删除指定应用的所有事件
 * - cleanupOldEvents(_:): 清理指定时间之前的事件
 * 
 * ### 3. 查询统计 Query & Statistics
 * - getEventsByAppId(_:): 获取指定应用的事件列表
 * - getEventsByStatus(_:): 获取指定状态的事件列表
 * - getEventsByTimeRange(_:_:): 获取指定时间范围的事件
 * - getEventStatistics(): 获取事件统计信息
 * 
 * ### 4. 数据维护 Data Maintenance
 * - validateEvent(_:): 验证事件数据的有效性
 * - cleanupInvalidEvents(): 清理无效的事件记录
 * - optimizeDatabase(): 优化数据库性能
 * 
 * ## 使用示例
 * 
 * ### 基本事件操作
 * ```swift
 * let eventService = FirewallEventService.shared
 * 
 * // 记录新事件
 * let event = FirewallEvent(...)
 * try eventService.recordEvent(event)
 * 
 * // 获取事件
 * if let event = try eventService.getEventById("event-id") {
 *     print("Found event: \(event.description)")
 * }
 * 
 * // 删除事件
 * try eventService.deleteEvent("event-id")
 * ```
 * 
 * ### 批量操作
 * ```swift
 * // 批量记录事件
 * let events = [event1, event2, event3]
 * try eventService.recordEvents(events)
 * 
 * // 清理旧事件
 * let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
 * try eventService.cleanupOldEvents(before: oneWeekAgo)
 * ```
 * 
 * ### 统计查询
 * ```swift
 * // 获取事件统计
 * let stats = try eventService.getEventStatistics()
 * print("总事件: \(stats.total), 允许: \(stats.allowed), 阻止: \(stats.rejected)")
 * 
 * // 获取指定应用的事件
 * let appEvents = try eventService.getEventsByAppId("com.example.app")
 * print("应用事件数量: \(appEvents.count)")
 * ```
 * 
 * ## 最佳实践
 * 
 * ### 1. 性能优化
 * - 使用批量操作减少数据库访问
 * - 实现合适的数据清理策略
 * - 监控数据库大小和性能
 * 
 * ### 2. 内存管理
 * - 避免一次性加载大量事件数据
 * - 使用分页查询处理大数据集
 * - 及时释放不再使用的数据
 * 
 * ### 3. 数据一致性
 * - 确保事件数据的完整性
 * - 处理并发写入的冲突
 * - 实现适当的数据验证
 * 
 * ### 4. 错误处理
 * - 记录详细的错误日志
 * - 提供有意义的错误信息
 * - 实现优雅的降级策略
 */
class EventService: SuperLog {
    nonisolated static let emoji = "🔥"
    
    // MARK: - Properties

    /// FirewallEvent仓库
    private var repository: EventRepo

    // MARK: - Initialization

    /// 初始化防火墙事件服务
    init(repo: EventRepo) {
        self.repository = repo
    }

    // MARK: - Event Management

    /// 记录新的防火墙事件
    /// - Parameter event: 要记录的防火墙事件
    /// - Throws: 保存数据时可能抛出的错误
    func recordEvent(_ event: FirewallEvent) throws {
        let verbose = false
        if let validationError = validateEventWithReason(event) {
            throw FirewallEventError.invalidEvent(validationError)
        }
        
        try repository.create(event)
        if verbose {
        os_log("\(self.t)📝 Recorded firewall event: \(event.description) for app \(event.sourceAppIdentifier)")
    }}
    
    /// 批量记录防火墙事件
    /// - Parameter events: 要记录的防火墙事件数组
    /// - Throws: 保存数据时可能抛出的错误
    func recordEvents(_ events: [FirewallEvent]) throws {
        let validEvents = events.filter { validateEvent($0) }
        
        guard !validEvents.isEmpty else {
            throw FirewallEventError.noValidEvents("No valid events to record")
        }
        
        try repository.createBatch(validEvents)
        os_log("\(self.t)📝 Batch recorded \(validEvents.count) firewall events")
    }

    /// 根据ID获取防火墙事件
    /// - Parameter id: 事件ID
    /// - Returns: 找到的防火墙事件，如果未找到则返回nil
    /// - Throws: 查询数据时可能抛出的错误
    func getEventById(_ id: String) throws -> FirewallEvent? {
        guard let eventModel = try repository.find(id) else {
            return nil
        }
        return eventModel.toFirewallEvent()
    }

    /// 删除指定ID的防火墙事件
    /// - Parameter id: 事件ID
    /// - Throws: 删除数据时可能抛出的错误
    func deleteEvent(_ id: String) throws {
        try repository.delete(id)
        os_log("\(self.t)🗑️ Deleted firewall event: \(id)")
    }
    
    /// 删除指定应用的所有防火墙事件
    /// - Parameter appId: 应用程序ID
    /// - Throws: 删除数据时可能抛出的错误
    func deleteEventsByAppId(_ appId: String) throws {
        let eventCount = try repository.getEventCountByAppId(appId)
        try repository.deleteByAppId(appId)
        os_log("\(self.t)🗑️ Deleted \(eventCount) firewall events for app: \(appId)")
    }

    // MARK: - Query Operations

    /// 获取指定应用的所有防火墙事件
    /// - Parameter appId: 应用程序ID
    /// - Returns: 该应用的防火墙事件数组
    /// - Throws: 查询数据时可能抛出的错误
    func getEventsByAppId(_ appId: String) throws -> [FirewallEvent] {
        os_log("\(self.t)获取防火墙事件: \(appId)")
        let eventModels = try repository.fetchByAppId(appId)
        return eventModels.map { $0.toFirewallEvent() }
    }
    
    /// 获取指定应用的防火墙事件（分页）
    /// - Parameters:
    ///   - appId: 应用程序ID
    ///   - page: 页码（从0开始）
    ///   - pageSize: 每页记录数
    ///   - statusFilter: 状态筛选（可选）
    ///   - directionFilter: 方向筛选（可选）
    /// - Returns: 分页后的防火墙事件数组
    /// - Throws: 查询数据时可能抛出的错误
    func getEventsByAppIdPaginated(
        _ appId: String,
        page: Int,
        pageSize: Int,
        statusFilter: FirewallEvent.Status? = nil,
        directionFilter: NETrafficDirection? = nil
    ) throws -> [FirewallEvent] {
        os_log("\(self.t)获取防火墙事件(分页): \(appId), 页码: \(page), 每页: \(pageSize)")
        
        let eventModels = try repository.fetchByAppIdPaginated(
            appId,
            page: page,
            pageSize: pageSize,
            statusFilter: statusFilter,
            directionFilter: directionFilter
        )
        
        return eventModels.map { $0.toFirewallEvent() }
    }
    
    /// 获取指定应用的防火墙事件总数
    /// - Parameters:
    ///   - appId: 应用程序ID
    ///   - statusFilter: 状态筛选（可选）
    ///   - directionFilter: 方向筛选（可选）
    /// - Returns: 符合条件的事件总数
    /// - Throws: 查询数据时可能抛出的错误
    func getEventCountByAppId(
        _ appId: String,
        statusFilter: FirewallEvent.Status? = nil,
        directionFilter: NETrafficDirection? = nil
    ) throws -> Int {
        return try repository.getEventCountByAppIdFiltered(
            appId,
            statusFilter: statusFilter,
            directionFilter: directionFilter
        )
    }
    
    /// 获取指定状态的所有防火墙事件
    /// - Parameter status: 防火墙状态
    /// - Returns: 指定状态的防火墙事件数组
    /// - Throws: 查询数据时可能抛出的错误
    func getEventsByStatus(_ status: FirewallEvent.Status) throws -> [FirewallEvent] {
        let eventModels = try repository.fetchByStatus(status)
        return eventModels.map { $0.toFirewallEvent() }
    }
    
    /// 获取指定网络流量方向的所有防火墙事件
    /// - Parameter direction: 网络流量方向
    /// - Returns: 指定方向的防火墙事件数组
    /// - Throws: 查询数据时可能抛出的错误
    func getEventsByDirection(_ direction: NETrafficDirection) throws -> [FirewallEvent] {
        let eventModels = try repository.fetchByDirection(direction)
        return eventModels.map { $0.toFirewallEvent() }
    }

    /// 获取指定时间范围内的防火墙事件
    /// - Parameters:
    ///   - startDate: 开始时间
    ///   - endDate: 结束时间
    /// - Returns: 指定时间范围内的防火墙事件数组
    /// - Throws: 查询数据时可能抛出的错误
    func getEventsByTimeRange(from startDate: Date, to endDate: Date) throws -> [FirewallEvent] {
        let eventModels = try repository.fetchByTimeRange(from: startDate, to: endDate)
        return eventModels.map { $0.toFirewallEvent() }
    }
    
    /// 获取指定地址的所有防火墙事件
    /// - Parameter address: 目标地址
    /// - Returns: 指定地址的防火墙事件数组
    /// - Throws: 查询数据时可能抛出的错误
    func getEventsByAddress(_ address: String) throws -> [FirewallEvent] {
        let eventModels = try repository.fetchByAddress(address)
        return eventModels.map { $0.toFirewallEvent() }
    }
    
    /// 获取最新的防火墙事件
    /// - Parameter limit: 限制数量，默认100
    /// - Returns: 最新的防火墙事件数组
    /// - Throws: 查询数据时可能抛出的错误
    func getLatestEvents(limit: Int = 100) throws -> [FirewallEvent] {
        let eventModels = try repository.fetchLatest(limit: limit)
        return eventModels.map { $0.toFirewallEvent() }
    }
    
    /// 获取所有防火墙事件（分页）
    /// - Parameters:
    ///   - page: 页码（从0开始）
    ///   - pageSize: 每页记录数
    /// - Returns: 分页后的防火墙事件数组
    /// - Throws: 查询数据时可能抛出的错误
    func getAllEventsPaginated(
        page: Int,
        pageSize: Int
    ) throws -> [FirewallEvent] {
        os_log("\(self.t)获取所有防火墙事件(分页), 页码: \(page), 每页: \(pageSize)")
        
        let eventModels = try repository.fetchAllPaginated(
            page: page,
            pageSize: pageSize
        )
        
        return eventModels.map { $0.toFirewallEvent() }
    }
    
    /// 获取所有防火墙事件
    /// - Returns: 所有防火墙事件数组
    /// - Throws: 查询数据时可能抛出的错误
    func getAllEvents() throws -> [FirewallEvent] {
        let eventModels = try repository.fetchAll()
        return eventModels.map { $0.toFirewallEvent() }
    }

    // MARK: - Statistics

    /// 获取防火墙事件统计信息
    /// - Returns: 包含总数、允许和拒绝数量的统计信息
    /// - Throws: 查询数据时可能抛出的错误
    func getEventStatistics() throws -> (total: Int, allowed: Int, rejected: Int) {
        let totalCount = try repository.getEventCount()
        let allowedCount = try repository.getAllowedEventCount()
        let rejectedCount = try repository.getRejectedEventCount()
        
        return (total: totalCount, allowed: allowedCount, rejected: rejectedCount)
    }
    
    /// 获取指定应用的事件统计信息
    /// - Parameter appId: 应用程序ID
    /// - Returns: 包含总数、允许和拒绝数量的统计信息
    /// - Throws: 查询数据时可能抛出的错误
    func getEventStatisticsByAppId(_ appId: String) throws -> (total: Int, allowed: Int, rejected: Int) {
        let allEvents = try getEventsByAppId(appId)
        let allowedCount = allEvents.filter { $0.status == .allowed }.count
        let rejectedCount = allEvents.filter { $0.status == .rejected }.count
        
        return (total: allEvents.count, allowed: allowedCount, rejected: rejectedCount)
    }
    
    /// 获取今日事件统计信息
    /// - Returns: 今日的事件统计信息
    /// - Throws: 查询数据时可能抛出的错误
    func getTodayEventStatistics() throws -> (total: Int, allowed: Int, rejected: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let todayEvents = try getEventsByTimeRange(from: today, to: tomorrow)
        let allowedCount = todayEvents.filter { $0.status == .allowed }.count
        let rejectedCount = todayEvents.filter { $0.status == .rejected }.count
        
        return (total: todayEvents.count, allowed: allowedCount, rejected: rejectedCount)
    }

    // MARK: - Data Maintenance

    /// 验证防火墙事件数据的有效性
    /// - Parameter event: 要验证的防火墙事件
    /// - Returns: 如果事件有效返回true，否则返回false
    func validateEvent(_ event: FirewallEvent) -> Bool {
        return validateEventWithReason(event) == nil
    }
    
    /// 验证防火墙事件数据的有效性并返回具体的失败原因
    /// - Parameter event: 要验证的防火墙事件
    /// - Returns: 如果事件有效返回nil，否则返回具体的错误原因
    private func validateEventWithReason(_ event: FirewallEvent) -> String? {
        // 检查ID字段
        if event.id.isEmpty {
            return "事件ID不能为空"
        }
        
        // 检查地址字段
        if event.address.isEmpty {
            return "地址不能为空"
        }
        
        // 检查端口字段
        if event.port.isEmpty {
            return "端口不能为空"
        }
        
        // 检查时间是否合理（不能是未来时间）
        if event.time > Date() {
            return "事件时间不能是未来时间"
        }
        
        // 检查端口号是否有效
        guard let portNumber = Int(event.port) else {
            return "端口号格式无效: \(event.port)"
        }
        
        // 允许端口为0（表示未知端口），因为防火墙事件并不总是包含有效的端口信息
        if portNumber < 0 {
            return "端口号不能为负数，当前值: \(portNumber)"
        }
        
        if portNumber > 65535 {
            return "端口号不能超过65535，当前值: \(portNumber)"
        }
        
        return nil
    }
    
    /// 清理指定时间之前的防火墙事件
    /// - Parameter date: 截止日期
    /// - Throws: 删除数据时可能抛出的错误
    func cleanupOldEvents(before date: Date) throws {
        let oldEvents = try repository.fetchByTimeRange(from: Date.distantPast, to: date)
        let eventCount = oldEvents.count
        
        try repository.deleteBefore(date)
        
        if eventCount > 0 {
            os_log("\(self.t)🧹 Cleaned up \(eventCount) old firewall events before \(date)")
        }
    }
    
    /// 清理无效的防火墙事件记录
    /// - Throws: 删除数据时可能抛出的错误
    func cleanupInvalidEvents() throws {
        let allEvents = try getAllEvents()
        var deletedCount = 0
        
        for event in allEvents {
            if !validateEvent(event) {
                try deleteEvent(event.id)
                deletedCount += 1
            }
        }
        
        if deletedCount > 0 {
            os_log("\(self.t)🧹 Cleaned up \(deletedCount) invalid firewall event records")
        }
    }
    
    /// 优化数据库性能（清理旧数据，保留最近的事件）
    /// - Parameter maxEvents: 最大保留事件数量，默认10000
    /// - Throws: 操作数据时可能抛出的错误
    func optimizeDatabase(maxEvents: Int = 10000) throws {
        let totalCount = try repository.getEventCount()
        
        if totalCount > maxEvents {
            // 计算需要删除的事件数量
            let eventsToDelete = totalCount - maxEvents
            
            // 获取最旧的事件，计算截止时间
            let allEvents = try repository.fetchAll()
            let sortedEvents = allEvents.sorted { $0.time < $1.time }
            
            if eventsToDelete < sortedEvents.count {
                let cutoffDate = sortedEvents[eventsToDelete - 1].time
                try cleanupOldEvents(before: cutoffDate)
                
                os_log("\(self.t)⚡ Database optimized: removed \(eventsToDelete) old events")
            }
        }
    }
}

// MARK: - Error Types

/// 防火墙事件服务错误类型
enum FirewallEventError: Error, LocalizedError {
    case invalidEvent(String)
    case noValidEvents(String)
    case databaseError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEvent(let message):
            return "Invalid event: \(message)"
        case .noValidEvents(let message):
            return "No valid events: \(message)"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}

#Preview("FirewallEvent Service") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
