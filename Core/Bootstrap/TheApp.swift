import SwiftUI

/**
 * 应用程序主入口
 * 使用MenuBarExtra作为主要界面，通过AppDelegate处理首次启动的欢迎窗口
 */
@main
struct TheApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow
    @State private var isWelcomePresented = true
    
    var body: some Scene {
        // 主要的菜单栏应用
        MenuBarExtra("TravelMode", systemImage: "network") {
            RootView {
                ContentView()
            }
            .frame(minHeight: 500)
            .frame(minWidth: 300)
            .onReceive(NotificationCenter.default.publisher(for: .openWelcomeWindow)) { _ in
                openWindow(id: "welcome")
            }
        }
        .menuBarExtraStyle(.window)
        
        // 欢迎引导窗口
        Window("Welcome to TravelMode", id: "welcome") {
            WelcomeGuideView(isPresented: $isWelcomePresented)
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultSize(width: 500, height: 600)
        .keyboardShortcut("w", modifiers: [.command, .shift])
    }
}

/**
 * 应用程序代理，处理应用启动逻辑
 */
class AppDelegate: NSObject, NSApplicationDelegate {
    /**
     * 应用启动完成后的处理
     * 检查是否需要显示欢迎窗口
     */
    func applicationDidFinishLaunching(_ notification: Notification) {
        let hasShownWelcome = UserDefaults.standard.bool(forKey: "hasShownWelcome")
        
        if !hasShownWelcome {
            // 延迟1秒确保应用完全启动
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NotificationCenter.default.post(name: .openWelcomeWindow, object: nil)
            }
        }
    }
}

/**
 * 通知扩展，用于窗口打开通信
 */
extension Notification.Name {
    static let openWelcomeWindow = Notification.Name("openWelcomeWindow")
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
