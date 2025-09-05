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
