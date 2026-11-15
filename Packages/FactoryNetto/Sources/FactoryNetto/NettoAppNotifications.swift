import Foundation

/**
 * App 场景内部通知名（从旧 FirewallService+Event.swift 迁出）。
 *
 * 所有权：仅 Factory 场景宿主（监听）与 HostGuidePlugin/BtnGuide（发送）使用；
 * 均为无负载的壳内信号，不跨插件传对象。
 * - shouldOpenWelcomeWindow：打开欢迎引导窗口。
 */
extension Notification.Name {
    /// 打开欢迎引导窗口（TheApp 监听，BtnGuide 发送）。
    static let shouldOpenWelcomeWindow = Notification.Name("shouldOpenWelcomeWindow")
}
