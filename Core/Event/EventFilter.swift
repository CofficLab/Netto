import Foundation

/// 过滤器事件扩展
extension Notification.Name {
    static let NetWorkFilterFlow = Notification.Name("NetWorkFilterFlow")
    static let FilterStatusChanged = Notification.Name("FilterStatusChanged")
    static let NeedApproval = Notification.Name("NeedApproval")
    static let WaitingForApproval = Notification.Name("WaitingForApproval")
    static let PermissionDenied = Notification.Name("PermissionDenied")
    static let ProviderSaid = Notification.Name("ProviderSaid")
}
