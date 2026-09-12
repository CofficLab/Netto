import LumiUI
import MagicCore
import OSLog
import ProviderSettingView
import SwiftUI

/**
 * 应用程序主入口
 * 使用MenuBarExtra作为主要界面，通过AppDelegate处理首次启动的欢迎窗口
 *
 * 阶段 6 迁移后：App 启动期通过 `AppEnvironment.bootstrap()` 装配
 * FactoryNetto 内核（KernelCore + 插件目录），不再在视图 body 中创建服务。
 */
@main
struct TheApp: App, SuperEvent, SuperThread, SuperLog {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    @State private var shouldShowLoading = true
    @State private var shouldShowMenuApp = false
    @State private var shouldShowWelcomeWindow = false
    @State private var hasDeniedApps = false

    /// App 装配宿主（唯一实例；Kernel/契约/UI 状态在此缓存）。
    @StateObject private var appEnv: AppEnvironment

    init() {
        // 统一 LumiUI 视觉：注入内置回退 chrome 主题（氛围渐变背景），
        // UI 主题用 LumiUI 内置 LumiDefaultTheme（森林墨）作为兜底，
        // 与 Lumi 的启动即渲染一致，避免透明占位主题造成的样式缺失。
        ChromeThemes.current = LumiFallbackChromeTheme()
        setTheme(LumiDefaultTheme())

        // 通过局部引用启动由 StateObject 持有的同一个环境，不能在 App.init 中
        // 读取 appEnv wrappedValue（此时 SwiftUI 尚未安装 StateObject）。
        let environment = AppEnvironment.make()
        _appEnv = StateObject(wrappedValue: environment)
        Task {
            await environment.bootstrap()
        }
    }

    /// 检查是否有被禁止的应用（契约路径，替代 AppSettingRepo.shared）。
    private func checkDeniedApps() async {
        guard let settings = appEnv.settings else { return }
        do {
            let deniedCount = try await settings.deniedAppsCount()
            await MainActor.run {
                self.hasDeniedApps = deniedCount > 0
            }
        } catch {
            os_log("\(self.t)检查被禁止应用时出错: \(error.localizedDescription)")
        }
    }

    /// 等环境启动完成后绑定窗口路由，并刷新菜单栏警告状态。
    private func connectRunningEnvironment() {
        guard appEnv.phase == .running else { return }
        appEnv.shell?.onRequestOpen = { request in
            openWindow(id: request.windowID)
        }
        Task {
            await checkDeniedApps()
        }
    }

    nonisolated static let emoji = "🐦"
    static let welcomeWindowTitle = "Welcome to TravelMode"
    static let storeWindowTitle = "Store - TravelMode"
    private let versionService = VersionService()

    #if DEBUG
        private let isDebug = true
    #else
        private let isDebug = false
    #endif

    var body: some Scene {
        // 欢迎引导窗口
        Window(Self.welcomeWindowTitle, id: AppConfig.welcomeWindowId) {
            if shouldShowLoading && !shouldShowWelcomeWindow {
                LoadingView(isPresented: $shouldShowLoading, message: "启动中")
                    .onAppear {
                        let shouldShowWelcome = versionService.shouldShowWelcomeWindow()

                        os_log("\(self.t)🚩 检查版本，shouldShowWelcome: \(shouldShowWelcome)")

                        self.shouldShowWelcomeWindow = shouldShowWelcome
                        self.shouldShowLoading = false
                    }
            }

            if shouldShowWelcomeWindow {
                WelcomeGuideView()
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
        Window("设置", id: AppConfig.settingsWindowId) {
            if let settingsWindowView = appEnv.settingsWindowView {
                settingsWindowView
                    .appThemedAppearance()
            } else {
                ProgressView("启动中…")
                    .frame(minWidth: 720, minHeight: 460)
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

        // 主要的菜单栏应用
        MenuBarExtra(content: {
            RootView(environment: appEnv) {
                if shouldShowMenuApp == false {
                    Color.red.frame(height: 0)
                } else {
                    ContentView()
                        .frame(minHeight: 500)
                        .frame(minWidth: 400)
                }
            }
            .onAppear {
                // 用户点击了菜单栏图标
                shouldShowMenuApp = true
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
                shouldShowMenuApp = false
            }
            .onReceive(NotificationCenter.default.publisher(for: SettingViewNavigation.openSettingsNotification)) { notification in
                // 深链：选中目标设置入口后打开设置窗口（复刻 Lumi 行为）。
                if let settingsView = appEnv.kernel?.resolveProvider(SettingViewProviding.self),
                   let entryID = notification.userInfo?[SettingViewNavigation.entryIDUserInfoKey] as? String,
                   settingsView.entries.contains(where: { $0.id == entryID }) {
                    settingsView.selectEntry(id: entryID)
                }
                openWindow(id: AppConfig.settingsWindowId)
            }
            .onReceive(nc.publisher(for: .firewallDidSetDeny)) { _ in
                // 当有应用被禁止时，重新检查状态
                Task {
                    await checkDeniedApps()
                }
            }
            .onReceive(nc.publisher(for: .firewallDidSetAllow)) { _ in
                // 当有应用被允许时，重新检查状态
                Task {
                    await checkDeniedApps()
                }
            }
        }, label: {
            // MenuBarExtra 的 label 在 status item 安装时渲染一次：
            // 这是 App 启动的可靠 hook，用于显式打开设置窗口
            // （MenuBarExtra app 中 Window Scene 不会自动创建窗口，
            // 需 openWindow；内容在 bootstrap 完成前显示启动态）。
            Group {
                if hasDeniedApps {
                    // 有被禁止应用时显示警告图标
                    Image(systemName: isDebug ? "airplane.departure" : "network.badge.shield.half.filled")
                } else {
                    // 正常状态显示默认图标
                    Image(systemName: isDebug ? "airplane" : "checkmark.circle.fill")
                }
            }
            .onAppear {
                openWindow(id: AppConfig.settingsWindowId)
            }
        })
        .menuBarExtraStyle(.window)
    }
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(width: 500)
        .frame(height: 800)
}
