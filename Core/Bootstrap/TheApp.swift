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
    @StateObject private var pluginWindowManager = PluginWindowManager.shared

    nonisolated static let emoji = "🐦"
    static let welcomeWindowTitle = "Welcome to TravelMode"
    static let storeWindowTitle = "Store - TravelMode"
    private let versionService = VersionService()

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
                            }
                        }
                    }
                }
            }
        }, label: {
            #if DEBUG
                Label(AppConfig.appName, systemImage: .iconAirplane)
                    .foregroundColor(.orange)
            #else
                Label(AppConfig.appName, systemImage: "network")
            #endif
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
