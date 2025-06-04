import Foundation

/// 数据库维护任务执行结果
struct DBMaintenanceResult {
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
