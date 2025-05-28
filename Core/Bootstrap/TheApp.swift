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

    @State private var shouldShowMenuApp = true
    @State private var shouldShowWelcomeWindow = false

    static let emoji = "🫙"

    var body: some Scene {
        // 欢迎引导窗口
        Window("Welcome to TravelMode", id: AppConfig.welcomeWindowId) {
            WelcomeGuideView(isPresented: $shouldShowWelcomeWindow)
                .onAppear {
                    // 确保窗口显示在最上层
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    // 将窗口置于最前面
                    main.async {
                        if let window = NSApplication.shared.windows.first(where: { $0.title == "Welcome to TravelMode" }) {
                            window.level = .floating
                            window.orderFrontRegardless()
                        }
                    }
                }
                .onReceive(nc.publisher(for: .shouldCloseWelcomeWindow)) { _ in
                    os_log("\(self.t) 接收到willCloseWelcomeWindow事件，关闭欢迎窗口")
                    shouldShowWelcomeWindow = false
                    shouldShowMenuApp = true
                }
                // 3秒发出关闭事件
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline:.now() + 3) {
                        self.nc.post(name: .shouldCloseWelcomeWindow, object: nil)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultSize(width: 500, height: 600)
        .keyboardShortcut("w", modifiers: [.command, .shift])
        
        // 主要的菜单栏应用
        MenuBarExtra("TravelMode", systemImage: "network") {
            RootView {
                if shouldShowMenuApp == false {
                    Color.red.frame(height: 0)
                } else {
                    ContentView()
                        .frame(minHeight: 500)
                        .frame(minWidth: 300)
                }
            }
            .onAppear {
                // 用户点击了菜单栏图标
                shouldShowMenuApp = true
            }
            .onDisappear {
                print("MenuBar window disappeared")
            }
            .onReceive(nc.publisher(for: .willOpenWelcomeWindow)) { _ in
                os_log("\(self.t) 接收到willOpenWelcomeWindow事件，打开欢迎窗口")
                openWindow(id: AppConfig.welcomeWindowId)
                shouldShowWelcomeWindow = true
                shouldShowMenuApp = false
            }
        }
        .menuBarExtraStyle(.window)
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
