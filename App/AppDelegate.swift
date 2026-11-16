import Foundation
import AppKit
import OSLog

/**
 * 应用程序代理，处理应用启动逻辑
 */
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        os_log("🍎 应用启动完成")
        NotificationCenter.default.post(name: .appDidFinishLaunching, object: nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        os_log("🍎 应用即将退出")
    }

    /// 菜单栏应用：关闭主窗口后继续驻留状态栏，不随最后一个窗口退出。
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let appDidFinishLaunching = Notification.Name("appDidFinishLaunching")
}
