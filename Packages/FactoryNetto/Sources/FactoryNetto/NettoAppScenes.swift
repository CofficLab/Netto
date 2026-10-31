import AppKit
import Combine
import LumiUI
import OSLog
import ProviderSettingView
import ProviderShell
import SwiftUI

/// TravelMode 的 SwiftUI 场景装配器。App Target 只创建共享环境并把场景交给
/// SwiftUI；窗口内容、路由、启动引导和插件视图都由 Factory 负责。
///
/// ## 窗口路由的关键设计
///
/// Netto 是 `LSUIElement` 菜单栏应用：启动时 `Group` 场景里只有**第一个**
/// `Window`（欢迎窗口）会自动呈现，其余场景（设置窗口、插件窗口）需要
/// `openWindow(id:)` 主动打开。
///
/// `openWindow` 只能从视图的 `Environment` 拿到，因此**必须**由一个启动时
/// 必定出现的场景来捕获 —— 本文件用欢迎窗口场景捕获后交给
/// `SettingsWindowRouter`（常驻宿主）持有。设置窗口自己的场景**不再**
/// 捕获 `openWindow`、**不再**监听路由通知，否则会形成「要先有设置窗口
/// 才能打开设置窗口」的鸡生蛋死锁。
@MainActor
public struct NettoAppScenes: Scene {
    private let environment: AppEnvironment

    /// 窗口路由宿主（常驻；持有捕获到的 `openWindow`）。
    private let router: SettingsWindowRouter

    @Environment(\.openWindow) private var openWindow

    public init(environment: AppEnvironment) {
        self.environment = environment
        self.router = environment.router
    }

    public var body: some Scene {
        Group {
            Window(ShellWindowTitle.welcome, id: ShellWindowID.welcome) {
                WelcomeWindowHost(environment: environment, router: router)
            }
            .windowStyle(.hiddenTitleBar)
            .windowResizability(.contentSize)
            .defaultPosition(.center)
            .defaultSize(width: 500, height: 600)

            Window(ShellWindowTitle.settings, id: ShellWindowID.settings) {
                SettingsWindowHost(environment: environment)
            }
            .windowStyle(.hiddenTitleBar)
            .windowResizability(.contentSize)
            .defaultPosition(.center)
            // LumiSettings 的双栏设置视图最小尺寸为 960x520，这里给足空间。
            .defaultSize(width: 960, height: 520)

            Window(ShellWindowTitle.plugin, id: ShellWindowID.plugin) {
                PluginWindowHost(environment: environment)
            }
            .windowStyle(.hiddenTitleBar)
            .windowResizability(.contentSize)
            .defaultPosition(.center)
            .defaultSize(width: 600, height: 800)
        }
        .commands {
            NettoAppCommands(router: router)
        }
    }
}

/// 应用菜单命令 —— 提供 `⌘,`「设置…」入口。
///
/// 放在**常驻的 App 级**而不是某个窗口场景里：菜单栏应用启动时可能只有
/// 欢迎窗口存在，但 `⌘,` 必须始终可用。
@MainActor
struct NettoAppCommands: Commands {
    let router: SettingsWindowRouter

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("设置…") {
                router.openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)
            .accessibilityIdentifier("netto.settings.command")
        }
    }
}

@MainActor
private struct WelcomeWindowHost: View {
    @ObservedObject var environment: AppEnvironment
    @ObservedObject var router: SettingsWindowRouter

    var body: some View {
        Group {
            if shouldShowLoading && !environment.shouldShowWelcomeWindow {
                ProgressView("正在检查版本…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        let shouldShowWelcome = versionService.shouldShowWelcomeWindow()
                        os_log("🐦 检查版本，shouldShowWelcome: \(shouldShowWelcome)")
                        environment.shouldShowWelcomeWindow = shouldShowWelcome
                        shouldShowLoading = false
                    }
            }

            if environment.shouldShowWelcomeWindow {
                FactoryNetto.makeWelcomeGuideView()
                    .onAppear {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        if let window = NSApplication.shared.windows.first(where: {
                            $0.title == ShellWindowTitle.welcome
                        }) {
                            window.level = .floating
                            window.orderFrontRegardless()
                        }
                    }
            }
        }
        .onAppear {
            // 关键：欢迎窗口是**启动时必定出现**的场景，由它捕获 `openWindow`
            // 并交给常驻路由宿主。捕获到的动作在欢迎窗口关闭后依然有效
            // （实测），因此设置窗口随时可以被打开。
            router.attach(openWindow: openWindow)
            router.attach(settingViewProvider: environment.kernel?.resolveProvider(SettingViewProviding.self))
        }
    }

    @State private var shouldShowLoading = true
    private let versionService = VersionService()
    @Environment(\.openWindow) private var openWindow
}

@MainActor
private struct SettingsWindowHost: View {
    @ObservedObject var environment: AppEnvironment

    var body: some View {
        Group {
            if let settingsWindowView = environment.settingsWindowView {
                settingsWindowView
                    .appThemedAppearance()
                    // 详情区由插件贡献，其中的 `.navigationTitle` 会被 SwiftUI
                    // 提升为窗口标题；守卫负责把标题固定回「设置」。
                    .background(WindowTitleGuard(title: ShellWindowTitle.settings))
                    .accessibilityIdentifier("netto.settings.window")
            } else {
                ProgressView("启动中…")
                    .frame(minWidth: 720, minHeight: 460)
            }
        }
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

@MainActor
private struct PluginWindowHost: View {
    @ObservedObject var environment: AppEnvironment

    var body: some View {
        Group {
            if let shell = environment.shell {
                PluginShellWindowHost(shell: shell)
            } else {
                Text("请选择一个插件功能")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

@MainActor
private struct PluginShellWindowHost: View {
    @ObservedObject var shell: ShellCenter

    var body: some View {
        Group {
            if let content = shell.currentContent {
                content.makeView()
                    .onAppear {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        if let window = NSApplication.shared.windows.first(where: { $0.title == content.title }) {
                            window.level = .floating
                            window.orderFrontRegardless()
                        }
                    }
            } else {
                Text("请选择一个插件功能")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
