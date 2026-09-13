import PluginFirewallDashboard
import Foundation

/**
 * App 壳内部通知名（阶段 8 从旧 FirewallService+Event.swift 迁出）。
 *
 * 所有权：仅 TheApp（监听）与 HostGuidePlugin/BtnGuide（发送）使用；
 * 均为无负载的壳内信号，不跨插件传对象。
 * - shouldOpenWelcomeWindow：打开欢迎引导窗口。
 * - firewallDidSetDeny / firewallDidSetAllow：菜单栏图标状态刷新信号，
 *   旧 AppSettingRepo 曾负责发送；现契约路径下由 UIProvider 状态驱动，
 *   此两名称保留仅为兼容旧监听（无发送方时为惰性监听）。
 */
extension Notification.Name {
    /// 打开欢迎引导窗口（TheApp 监听，BtnGuide 发送）。
    static let shouldOpenWelcomeWindow = Notification.Name("shouldOpenWelcomeWindow")

    /// 设置禁止后刷新菜单栏图标状态（兼容保留）。
    static let firewallDidSetDeny = Notification.Name("firewallDidSetDeny")

    /// 设置允许后刷新菜单栏图标状态（兼容保留）。
    static let firewallDidSetAllow = Notification.Name("firewallDidSetAllow")
}
