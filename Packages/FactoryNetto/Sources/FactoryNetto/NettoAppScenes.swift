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
/// `Window`（主窗口）会自动呈现，其余场景（欢迎窗口、设置窗口、插件窗口）
/// 需要 `openWindow(id:)` 主动打开。
///
/// `openWindow` 只能从视图的 `Environment` 拿到，因此**必须**由一个启动时
/// 必定出现的场景来捕获 —— 本文件用主窗口场景捕获后交给
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
            Window(ShellWindowTitle.main, id: ShellWindowID.main) {
                MainWindowHost(environment: environment)
            }
            .windowStyle(.hiddenTitleBar)
            .windowResizability(.contentMinSize)
            .defaultPosition(.center)
            .defaultSize(width: 760, height: 800)

            Window(ShellWindowTitle.welcome, id: ShellWindowID.welcome) {
                WelcomeWindowHost(environment: environment)
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

/// 主窗口 Host —— 复杂界面（防火墙仪表盘）所在窗口，启动即打开。
///
/// 由它捕获 `openWindow` 交给常驻路由宿主；同时承担首次安装/重要版本升级
/// 时打开欢迎窗口的职责（欢迎窗口已不是第一个场景，不再自动呈现）。
@MainActor
private struct MainWindowHost: View {
    @ObservedObject var environment: AppEnvironment

    @Environment(\.openWindow) private var openWindow

    @State private var didCheckVersion = false

    var body: some View {
        FactoryNetto.makeRootView(environment: environment) {
            Group {
                if let kernel = environment.kernel {
                    FactoryNetto.makeMainView(
                        kernel: kernel,
                        ui: environment.ui,
                        appProvider: environment.appProvider,
                        sessionStartDate: environment.sessionStartDate
                    )
                }
            }
            .frame(minWidth: 640, minHeight: 600)
            .nettoMinimalWindowChrome()
        }
        .onAppear {
            // 启动即存在的场景负责捕获 openWindow（关闭后动作依然有效）。
            environment.router.attach(openWindow: openWindow)
            environment.router.attach(
                settingViewProvider: environment.kernel?.resolveProvider(SettingViewProviding.self)
            )
            NSApplication.shared.activate(ignoringOtherApps: true)
            checkVersionOnce()
        }
    }

    /// 首次安装或 major/minor 升级时打开欢迎引导窗口。
    private func checkVersionOnce() {
        guard !didCheckVersion else { return }
        didCheckVersion = true
        guard VersionService().shouldShowWelcomeWindow() else { return }
        environment.shouldShowWelcomeWindow = true
        environment.router.openWelcomeWindow()
    }
}

@MainActor
private struct WelcomeWindowHost: View {
    @ObservedObject var environment: AppEnvironment

    var body: some View {
        Group {
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
    }
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
