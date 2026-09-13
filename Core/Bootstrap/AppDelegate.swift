import Foundation
import AppKit
import MagicCore
import OSLog
import SwiftUI

/**
 * 应用程序代理，处理应用启动逻辑
 */
class AppDelegate: NSObject, NSApplicationDelegate, SuperEvent, SuperLog, SuperThread {
    @Environment(\.openWindow) private var openWindow
    static let emoji = "🍎"
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        os_log("\(self.t)✅ 应用启动完成")
        // 发送应用启动完成通知
        NotificationCenter.default.post(name: .appDidFinishLaunching, object: nil)

        // 阶段 6：防火墙 daemon/观察者由 PluginFirewall（onReadyAsync）在
        // AppEnvironment 内核启动时启动；此处不再创建 FirewallService.shared，
        // 避免与插件内真实 daemon 重复监听同一 Mach 服务。
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        os_log("\(self.t)应用即将退出")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let appDidFinishLaunching = Notification.Name("appDidFinishLaunching")
}
