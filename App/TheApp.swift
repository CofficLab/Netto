import LumiFactory
import ProviderShell
import SwiftUI

/// 应用入口：单个 target、单个 bundle id。
///
/// 装配流水线、窗口壳（主窗口 + 设置窗口 + ⌘, 命令）、状态栏宿主与生命周期
/// 协调全部由 LumiFactory 解释 `NettoManifest.manifest` 执行；本文件只负责把
/// 启动器接到 SwiftUI 入口，并声明 TravelMode 独有的欢迎引导窗口场景。
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
    }

    var body: some Scene {
        // 共享 macOS 场景：主窗口 + 设置窗口 + 应用命令。
        HostMacScenes(bootstrapper: NettoAssembly.bootstrapper).body

        // 欢迎引导窗口（首次安装 / 重要版本升级 / 插件主动请求时打开）。
        Window(ShellWindowTitle.welcome, id: ShellWindowID.welcome) {
            NettoWelcomeWindowHost(bootstrapper: NettoAssembly.bootstrapper)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultSize(width: 500, height: 600)
    }
}