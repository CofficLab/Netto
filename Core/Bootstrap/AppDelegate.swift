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
}
