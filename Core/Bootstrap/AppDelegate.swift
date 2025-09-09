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
    
    var gate: FirewallDaemon? = nil
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        os_log("\(self.t)✅ 应用启动完成")
        // 发送应用启动完成通知
        NotificationCenter.default.post(name: .appDidFinishLaunching, object: nil)
        
        Task {
            let repo = AppSettingRepo()
            let eventRepo = EventRepo.shared
            
            self.gate = await FirewallDaemon(repo: repo,eventRepo: eventRepo, reason: self.className)
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        os_log("\(self.t)应用即将退出")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let appDidFinishLaunching = Notification.Name("appDidFinishLaunching")
}
