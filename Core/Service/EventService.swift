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
    
    /// 获取所有防火墙事件
    /// - Returns: 所有防火墙事件数组
    /// - Throws: 查询数据时可能抛出的错误
    func getAllEvents() throws -> [FirewallEvent] {
        let eventModels = try repository.fetchAll()
        return eventModels.map { $0.toFirewallEvent() }
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
