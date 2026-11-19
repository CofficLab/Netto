import KernelCore
import LumiFactory
import LumiUI
import PluginFirewallDashboard
import SwiftUI

/// 宿主级装配单例：App.init 可能被 SwiftUI 多次求值，启动器与共享 UI 状态
/// 必须经单例创建，保证视图持有的与注入 AppDelegate 的是同一个实例。
///
/// 装配流水线、窗口壳、状态栏宿主全部由共享包 `LumiFactory` 解释
/// `NettoManifest.manifest` 执行；这里只持有真正属于宿主的生命周期对象：
/// 启动器、仪表盘 UI 状态、会话起始时间与欢迎窗口路由。
@MainActor
enum NettoAssembly {
    /// 内核启动器（菜单栏弹窗与设置窗口共享同一实例）。
    static let bootstrapper = KernelBootstrapper(manifest: NettoManifest.manifest)

    /// 仪表盘 UI 状态（弹窗列表与详情共享同一份）。
    static let ui = UIProvider()

    /// Store 等视图的兼容 UI 状态（弹窗与设置窗口共享同一份）。
    static let appProvider = AppProvider()

    /// 会话起始时间（旧 `EventRepo.sessionStartDate` 语义：App 启动时固定）。
    static let sessionStartDate = Date()

    /// 欢迎窗口路由（常驻；监听插件请求与版本升级触发）。
    static let welcomeRouter = NettoWelcomeRouter()

    /// 产品默认外观：主题 Provider 就绪前（加载页 / 欢迎窗）的兜底主题，
    /// 沿用旧 `AppEnvironment.make()` 的加载外观。
    static func prepareChromeTheme() {
        ChromeThemes.current = LumiFallbackChromeTheme()
        setTheme(LumiDefaultTheme())
    }
}