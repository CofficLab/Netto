import MagicCore
import OSLog
import SwiftUI

/**
 * 应用程序主入口
 * 使用MenuBarExtra作为主要界面，通过AppDelegate处理首次启动的欢迎窗口
 */
@main
struct TheApp: App, SuperEvent, SuperThread, SuperLog {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    @State private var shouldShowLoading = true
    @State private var shouldShowMenuApp = false
    @State private var shouldShowWelcomeWindow = false
    @State private var hasDeniedApps = false
    @StateObject private var pluginWindowManager = PluginWindowManager.shared

    init() {
        // 启动 Store 服务（监听 + 校准）
        StoreService.bootstrap()
    }

    /// 检查是否有被禁止的应用
    private func checkDeniedApps() async {
        do {
            let repo = AppSettingRepo.shared
            let deniedCount = try await repo.getDeniedAppsCount()
            await MainActor.run {
                self.hasDeniedApps = deniedCount > 0
            }
        } catch {
            os_log("\(self.t)检查被禁止应用时出错: \(error.localizedDescription)")
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
        // 启动时立即检查被禁止的应用
        let _ = Task {
            await checkDeniedApps()
        }

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

        // 插件窗口 - 动态显示插件内容
        Window("Plugin Window", id: "plugin-window") {
            Group {
                if let content = pluginWindowManager.currentContent {
                    content.windowView()
                        .onAppear {
                            // 确保窗口显示在最上层
                            NSApplication.shared.activate(ignoringOtherApps: true)
                            // 将窗口置于最前面
                            if let window = NSApplication.shared.windows.first(where: { $0.title == content.windowTitle }) {
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
            RootView {
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
                // 检查被禁止的应用
                Task {
                    await checkDeniedApps()
                }
            }
            .onReceive(nc.publisher(for: .shouldOpenWelcomeWindow)) { _ in
                os_log("\(self.t)🖥️ 打开欢迎窗口")
                openWindow(id: AppConfig.welcomeWindowId)
                shouldShowWelcomeWindow = true
                shouldShowMenuApp = false
            }
            .onReceive(nc.publisher(for: .shouldOpenPluginWindow)) { notification in
                os_log("\(self.t)🔌 打开插件窗口")
                // 从通知中获取插件 ID
                if let data = notification.object as? PluginWindowNotificationData {
                    Task {
                        if let plugin = await PluginRegistry.shared.getPlugin(id: data.pluginId),
                           let windowContent = plugin.provideWindowContent() {
                            await MainActor.run {
                                pluginWindowManager.showWindow(with: windowContent)
                                openWindow(id: "plugin-window")
                                shouldShowMenuApp = false

                                // 确保窗口置顶
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    NSApplication.shared.activate(ignoringOtherApps: true)

                                    // 查找插件窗口并置顶
                                    if let pluginWindow = NSApplication.shared.windows.first(where: {
                                        $0.title == windowContent.windowTitle || $0.title.contains("Plugin Window")
                                    }) {
                                        pluginWindow.level = .floating
                                        pluginWindow.orderFrontRegardless()
                                        pluginWindow.makeKeyAndOrderFront(nil)
                                    }
                                }
                            }
                        }
                    }
                }
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
            if hasDeniedApps {
                // 有被禁止应用时显示警告图标
                Image(systemName: isDebug ? "airplane.departure" : "network.badge.shield.half.filled")
            } else {
                // 正常状态显示默认图标
                Image(systemName: isDebug ? "airplane" : "checkmark.circle.fill")
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
