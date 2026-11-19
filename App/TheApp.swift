import LumiFactory
import ProviderShell
import SwiftUI

/// 应用入口：单个 target、单个 bundle id。
///
/// 菜单栏 App 没有常驻主窗口：防火墙仪表盘全部在状态栏弹窗里，设置窗口与
/// 欢迎窗口只在需要时打开。装配流水线、状态栏宿主与生命周期协调仍由
/// LumiFactory 解释 `NettoManifest.manifest` 执行；两个窗口场景由本文件声明，
/// 均以 `.suppressed` 启动行为注册，避免 SwiftUI 在启动时自动开窗。
///
/// `@NSApplicationDelegateAdaptor` 必须挂在 @main 根 App 上：SwiftUI 只为根 App
/// 安装代理，放在 body 里临时创建的嵌套结构上不会生效。
@main
struct TheApp: App {
    @NSApplicationDelegateAdaptor(HostAppDelegate.self) private var appDelegate

    init() {
        // 禁用窗口状态恢复必须在根 App.init 写入（恢复发生在 delegate 回调之前）。
        HostAppDelegate.prepareForLaunch()
        NettoAssembly.prepareChromeTheme()
        appDelegate.bootstrapper = NettoAssembly.bootstrapper
        // 没有主窗口，装配不能依赖任何窗口视图的 .task 触发；启动即装配，
        // 内核就绪后 delegate 才会安装状态栏入口。
        Task { await NettoAssembly.bootstrapper.boot() }
        // 首次安装 / 重要版本升级的欢迎引导：没有主窗口的 .task 可挂，改为启动即检查。
        NettoAssembly.welcomeRouter.checkVersionOnce()
    }

    var body: some Scene {
        // 设置窗口 + 应用命令（⌘, / 插件命令由共享 HostCommands 提供）。
        Window(ShellWindowTitle.settings, id: ShellWindowID.settings) {
            HostSettingsWindowView(bootstrapper: NettoAssembly.bootstrapper)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 960, height: 560)
        .defaultLaunchBehavior(.suppressed)
        .commands {
            HostCommands(bootstrapper: NettoAssembly.bootstrapper)
        }

        // 欢迎引导窗口（首次安装 / 重要版本升级 / 插件主动请求时打开）。
        Window(ShellWindowTitle.welcome, id: ShellWindowID.welcome) {
            NettoWelcomeWindowHost(bootstrapper: NettoAssembly.bootstrapper)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultSize(width: 500, height: 600)
        .defaultLaunchBehavior(.suppressed)
    }
}