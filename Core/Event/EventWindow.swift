import Foundation

/// 通知名称扩展
extension Notification.Name  {
//    /// 应该打开欢迎窗口的通知
    static let shouldOpenWelcomeWindow = Notification.Name("shouldOpenWelcomeWindow")
    
    /// 应该打开插件窗口的通知
    static let shouldOpenPluginWindow = Notification.Name("shouldOpenPluginWindow")
//
//    /// 将要打开欢迎窗口的通知
//    static let willOpenWelcomeWindow = Notification.Name("willOpenWelcomeWindow")
//
//    /// 已经打开欢迎窗口的通知
//    static let didOpenWelcomeWindow = Notification.Name("didOpenWelcomeWindow")
//
//    /// 将要关闭欢迎窗口的通知
//    static let willCloseWelcomeWindow = Notification.Name("willCloseWelcomeWindow")
//
//    /// 应该关闭欢迎窗口的通知
//    static let shouldCloseWelcomeWindow = Notification.Name("shouldCloseWelcomeWindow")
//    
//    /// 检查版本以决定是否显示欢迎窗口的通知
//    static let checkVersionForWelcomeWindow = Notification.Name("checkVersionForWelcomeWindow")
}

/// 插件窗口通知数据
public struct PluginWindowNotificationData {
    public let pluginId: String
    
    public init(pluginId: String) {
        self.pluginId = pluginId
    }
}
