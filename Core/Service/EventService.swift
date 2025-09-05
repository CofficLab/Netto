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
    private var repository: EventNewRepo

    // MARK: - Initialization

    /// 初始化防火墙事件服务
    init(repo: EventNewRepo) {
        self.repository = repo
    }

    // MARK: - Event Management

    /// 记录新的防火墙事件
    /// - Parameter event: 要记录的防火墙事件
    /// - Throws: 保存数据时可能抛出的错误
    func recordEvent(_ event: FirewallEvent) async throws {
        let verbose = false
        if let validationError = validateEventWithReason(event) {
            throw FirewallEventError.invalidEvent(validationError)
        }
        
        try await repository.create(event)
        if verbose {
        os_log("\(self.t)📝 Recorded firewall event: \(event.description) for app \(event.sourceAppIdentifier)")
    }}
    
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
