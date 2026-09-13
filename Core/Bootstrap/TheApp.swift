import FactoryNetto
import LumiUI
import MagicCore
import OSLog
import ProviderSettingView
import SwiftUI

/**
 * 应用程序主入口
 * AppKit 状态栏控制器承载菜单栏 popover；菜单栏内容由 Factory/Provider/Plugin 装配
 *
 * 阶段 6 迁移后：App 启动期通过 `AppEnvironment.bootstrap()` 装配
 * FactoryNetto 内核（KernelCore + 插件目录），不再在视图 body 中创建服务。
 */
@main
struct TheApp: App, SuperEvent, SuperThread, SuperLog {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    @State private var shouldShowLoading = true
    @State private var shouldShowWelcomeWindow = false

    /// App 装配宿主（唯一实例；具体场景 View 显式观察其状态）。
    /// 与 LumiApp 持有 Kernel 的方式一致：App 保存稳定引用，不在 App 上安装
    /// 一个依赖 View 生命周期的 StateObject。
    private let appEnv: AppEnvironment

    init() {
        // 统一 LumiUI 视觉：注入内置回退 chrome 主题（氛围渐变背景），
        // UI 主题用 LumiUI 内置 LumiDefaultTheme（森林墨）作为兜底，
        // 与 Lumi 的启动即渲染一致，避免透明占位主题造成的样式缺失。
        ChromeThemes.current = LumiFallbackChromeTheme()
        setTheme(LumiDefaultTheme())

        // App 持有唯一环境对象；RootView / SettingsWindowHost 负责观察其状态。
        let environment = AppEnvironment.make()
        appEnv = environment
        Task {
            await environment.bootstrap()
        }
    }

    /// 检查是否有被禁止的应用（契约路径，替代 AppSettingRepo.shared）。
    private func checkDeniedApps() async {
        guard let settings = appEnv.settings else { return }
        do {
            let deniedCount = try await settings.deniedAppsCount()
            appEnv.menuBarController.updateDeniedApps(deniedCount > 0)
        } catch {
            os_log("\(self.t)检查被禁止应用时出错: \(error.localizedDescription)")
        }
    }

    /// 等环境启动完成后绑定窗口路由，并刷新菜单栏警告状态。
    private func connectRunningEnvironment() {
        guard appEnv.phase == .running else { return }
        appEnv.shell?.onRequestOpen = { request in
            if request.windowID == AppConfig.settingsWindowId {
                openSettingsWindow()
            } else {
                openWindow(id: request.windowID)
            }
        }
        Task {
            await checkDeniedApps()
        }
    }

    /// Settings is a WindowGroup so it can be the app's launch scene; reuse its
    /// existing window when plugins request the settings route again.
    private func openSettingsWindow() {
        if let window = NSApp.windows.first(where: { $0.title == "设置" && $0.isVisible }) {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: AppConfig.settingsWindowId)
        }
    }

    nonisolated static let emoji = "🐦"
    static let welcomeWindowTitle = "Welcome to TravelMode"
    static let storeWindowTitle = "Store - TravelMode"
    private let versionService = VersionService()

    var body: some Scene {
        // 欢迎引导窗口
        Window(Self.welcomeWindowTitle, id: AppConfig.welcomeWindowId) {
            if shouldShowLoading && !shouldShowWelcomeWindow {
                ProgressView("正在检查版本…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        let shouldShowWelcome = versionService.shouldShowWelcomeWindow()

                        os_log("\(self.t)🚩 检查版本，shouldShowWelcome: \(shouldShowWelcome)")

                        self.shouldShowWelcomeWindow = shouldShowWelcome
                        self.shouldShowLoading = false
                    }
            }

            if shouldShowWelcomeWindow {
                FactoryNetto.makeWelcomeGuideView()
                    .onAppear {
                        // 确保窗口显示在最上层
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        // 将窗口置于最前面
                        if let window = NSApplication.shared.windows.first(where: { $0.title == Self.welcomeWindowTitle }) {
                            window.level = .floating
                            window.orderFrontRegardless()
                        }
                    }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultSize(width: 500, height: 600)

        // 设置窗口（复刻 Lumi 形态）：内容由 FactoryNetto.makeSettingsView
        // 在 bootstrap 完成时装配一次并缓存（AppEnvironment.settingsWindowView），
        // 渲染「左侧入口列表 + 右侧详情视图」；不在 body 中装配。
        // 未就绪时显示启动态，装配失败由 BootstrapFailureView 显式呈现。
        // 单窗口场景不会在菜单栏应用启动时自动弹出；插件请求时由 openWindow 打开。
        Window("设置", id: AppConfig.settingsWindowId) {
            SettingsWindowHost(environment: appEnv)
                .onAppear {
                    connectRunningEnvironment()
                }
                .onChange(of: appEnv.phase) { _, phase in
                    if phase == .running {
                        connectRunningEnvironment()
                    }
                }
                .onReceive(nc.publisher(for: .shouldOpenWelcomeWindow)) { _ in
                    os_log("\(self.t)🖥️ 打开欢迎窗口")
                    openWindow(id: AppConfig.welcomeWindowId)
                    shouldShowWelcomeWindow = true
                }
                .onReceive(NotificationCenter.default.publisher(for: SettingViewNavigation.openSettingsNotification)) { notification in
                    if let settingsView = appEnv.kernel?.resolveProvider(SettingViewProviding.self),
                       let entryID = notification.userInfo?[SettingViewNavigation.entryIDUserInfoKey] as? String,
                       settingsView.entries.contains(where: { $0.id == entryID }) {
                        settingsView.selectEntry(id: entryID)
                    }
                    openSettingsWindow()
                }
                .onReceive(nc.publisher(for: .firewallDidSetDeny)) { _ in
                    Task { await checkDeniedApps() }
                }
                .onReceive(nc.publisher(for: .firewallDidSetAllow)) { _ in
                    Task { await checkDeniedApps() }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultSize(width: 720, height: 480)

        // 插件窗口 - 动态显示 WindowProviding 贡献的内容
        Window("Plugin Window", id: "plugin-window") {
            Group {
                if let content = appEnv.shell?.currentContent {
                    content.makeView()
                        .onAppear {
                            // 确保窗口显示在最上层
                            NSApplication.shared.activate(ignoringOtherApps: true)
                            // 将窗口置于最前面
                            if let window = NSApplication.shared.windows.first(where: { $0.title == content.title }) {
                                window.level = .floating
                                window.orderFrontRegardless()
                            }
                        }
                } else {
                    Text("请选择一个插件功能")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultSize(width: 600, height: 800)
    }
}

/// App 场景不依赖 App 值类型重新求值来刷新设置内容；此 View 直接观察环境状态。
@MainActor
private struct SettingsWindowHost: View {
    @ObservedObject var environment: AppEnvironment

    var body: some View {
        Group {
            if let settingsWindowView = environment.settingsWindowView {
                settingsWindowView
                    .appThemedAppearance()
            } else {
                ProgressView("启动中…")
                    .frame(minWidth: 720, minHeight: 460)
            }
        }
    }
}
