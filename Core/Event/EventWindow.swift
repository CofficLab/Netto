import Foundation

/// 通知名称扩展
extension Notification.Name  {
    /// 将要打开欢迎窗口的通知
    static let willOpenWelcomeWindow = Notification.Name("willOpenWelcomeWindow")

    /// 应该关闭欢迎窗口的通知
    static let shouldCloseWelcomeWindow = Notification.Name("shouldCloseWelcomeWindow")
}
