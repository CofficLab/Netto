import Foundation
import SwiftUI

extension SmartApp {
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
    /// - Parameter id: 要查找的应用程序标识符
    /// - Returns: 找到的应用程序实例，如果未找到则返回nil
    static func getApp(_ id: String) -> NSRunningApplication? {
        let apps = getRunningAppList()

        for app in apps {
            let bundleIdentifier = app.bundleIdentifier

            guard let bundleIdentifier = bundleIdentifier else {
                continue
            }

            if bundleIdentifier == id {
                return app
            }
        }

        return nil
    }
}
