import Foundation

/// 过滤器事件扩展
extension Notification.Name {
    /// 网络流量过滤事件通知
    /// 当有新的网络流量需要过滤处理时发送此通知
    static let NetWorkFilterFlow = Notification.Name("NetWorkFilterFlow")
    
    /// 过滤器状态变更通知
    /// 当过滤器的运行状态发生改变时发送此通知
    static let FilterStatusChanged = Notification.Name("FilterStatusChanged")
    
    /// 需要用户批准通知
    /// 当某个网络请求需要用户手动批准时发送此通知
    static let NeedApproval = Notification.Name("NeedApproval")
    
    /// 等待用户批准通知
    /// 当系统正在等待用户对某个请求进行批准时发送此通知
    static let WaitingForApproval = Notification.Name("WaitingForApproval")
    
    /// 权限被拒绝通知
    /// 当用户拒绝授予某项权限时发送此通知
    static let PermissionDenied = Notification.Name("PermissionDenied")
    
    /// 提供者消息通知
    /// 当网络扩展提供者有消息需要传递给主应用时发送此通知
    static let ProviderSaid = Notification.Name("ProviderSaid")

    /// 设置允许操作完成通知
    /// 当用户设置某个应用或域名为允许状态后发送此通知
    static let didSetAllow = Notification.Name("didSetAllow")
    
    /// 设置拒绝操作完成通知
    /// 当用户设置某个应用或域名为拒绝状态后发送此通知
    static let didSetDeny = Notification.Name("didSetDeny")
}
