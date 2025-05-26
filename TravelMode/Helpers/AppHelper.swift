import AppKit
import Foundation
import OSLog
import SwiftUI

/// AppHelper
/// 
/// 提供与运行中的应用程序相关的实用功能。
struct AppHelper {
    /// 获取当前系统中所有正在运行的应用程序列表
    ///
    /// - Returns: 包含所有正在运行的应用程序的数组
    static func getRunningAppList() -> [NSRunningApplication] {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications

        return runningApps
    }

    /// 根据标识符查找正在运行的应用程序
    ///
    /// 该方法通过提供的标识符在当前运行的应用程序中查找匹配的应用程序。
    /// 查找规则如下：
    /// - 如果标识符以点(.)开头，会自动移除开头的点
    /// - 匹配规则（满足任一即匹配成功）：
    ///   - 完全匹配应用程序的bundle identifier
    ///   - 完全匹配原始输入的标识符
    ///   - 输入的标识符包含应用程序的bundle identifier
    ///   - 输入的标识符以应用程序的bundle identifier结尾
    ///
    /// - Parameter id: 要查找的应用程序标识符
    /// - Returns: 找到的应用程序实例，如果未找到则返回nil
    static func getApp(_ id: String) -> NSRunningApplication? {
        var workId = id

        if workId.hasPrefix(".") {
            workId = String(workId.dropFirst())
        }

        let apps = getRunningAppList()

        for app in apps {
            let bundleIdentifier = app.bundleIdentifier
            
            
            guard let bundleIdentifier = bundleIdentifier else {
                continue
            }
            
            if
                bundleIdentifier == workId ||
                bundleIdentifier == id ||
                id.contains(bundleIdentifier) ||
                id.hasSuffix(bundleIdentifier) {
                return app
            }
        }

        return nil
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
