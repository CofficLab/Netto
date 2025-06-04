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

    /**
     * 应用启动完成后的处理
     * 检查是否需要显示欢迎窗口
     * 基于semantic versioning规则：只有major或minor版本更新时才显示welcome界面
     */
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 延迟执行，确保RootView已经初始化
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 通过通知中心获取ServiceProvider
            NotificationCenter.default.post(name: .checkVersionForWelcomeWindow, object: nil)
        }
    }


}
