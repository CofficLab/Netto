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
    @State private var shouldShowMenuApp = true
    @State private var shouldShowWelcomeWindow = false

    nonisolated static let emoji = "🐦"
    static let welcomeWindowTitle = "Welcome to TravelMode"

    var body: some Scene {
        // 欢迎引导窗口
        Window(Self.welcomeWindowTitle, id: AppConfig.welcomeWindowId) {
                if shouldShowLoading && !shouldShowWelcomeWindow {
                    // 使用 RootView 包裹，让 Providers 开始初始化
                    RootView {
                        LoadingView(isPresented: $shouldShowLoading, message: "启动中")
                            .onReceive(nc.publisher(for: .shouldOpenWelcomeWindow)) { _ in
                                os_log("\(self.t)🖥️ 打开欢迎窗口")
                                openWindow(id: AppConfig.welcomeWindowId)
                                shouldShowWelcomeWindow = true
                                shouldShowMenuApp = false
                            }
                            .onReceive(nc.publisher(for:.shouldCloseWelcomeWindow)) { _ in
                                os_log("\(self.t)🖥️ 关闭欢迎窗口，关闭LoadingView")
                                shouldShowWelcomeWindow = false
                                shouldShowLoading = false
                                shouldShowMenuApp = true
                            }
                    }
                }
                
                if shouldShowWelcomeWindow {
                    WelcomeGuideView()
                        .onAppear {
                            // 确保窗口显示在最上层
                            NSApplication.shared.activate(ignoringOtherApps: true)
                            // 将窗口置于最前面
//                            main.async {
                                if let window = NSApplication.shared.windows.first(where: { $0.title == Self.welcomeWindowTitle }) {
                                    window.level = .floating
                                    window.orderFrontRegardless()
                                }
//                            }
                        }
                        .onReceive(nc.publisher(for: .shouldCloseWelcomeWindow)) { _ in
                            os_log("\(self.t)关闭欢迎窗口")
                            shouldShowWelcomeWindow = false
                            shouldShowMenuApp = true
                        }
                }
            
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultSize(width: 500, height: 600)
        .keyboardShortcut("w", modifiers: [.command, .shift])
        
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
        }, label: {
            Label(AppConfig.appName, systemImage: "network")
        })
        .menuBarExtraStyle(.window)
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
