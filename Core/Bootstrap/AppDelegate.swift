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
        let shouldShowWelcome = shouldShowWelcomeWindow()

        os_log("\(self.t)🚩 did finish launching, shouldShowWelcome: \(shouldShowWelcome)")

        if shouldShowWelcome {
            self.nc.post(name: .shouldOpenWelcomeWindow, object: nil)
        } else {
            self.nc.post(name:.shouldCloseWelcomeWindow, object: nil)
        }
    }

    /**
     * 判断是否应该显示欢迎窗口
     * 基于版本比较逻辑：
     * - 首次安装：显示
     * - patch版本更新（x.y.z -> x.y.z+1）：不显示
     * - minor版本更新（x.y.z -> x.y+1.0）：显示
     * - major版本更新（x.y.z -> x+1.0.0）：显示
     */
    private func shouldShowWelcomeWindow() -> Bool {
        let lastShownVersion = UserDefaults.standard.string(forKey: "lastShownWelcomeVersion")
        let currentVersion = getCurrentAppVersion()

        os_log("\(self.t)🚩 lastShownVersion: \(lastShownVersion ?? "nil"), currentVersion: \(currentVersion)")

        // 首次安装或无法获取版本信息
        guard let lastVersion = lastShownVersion, !lastVersion.isEmpty else {
            // 记录当前版本
            os_log("\(self.t) 首次安装，显示欢迎窗口，并记录当前版本：\(currentVersion)")
            UserDefaults.standard.set(currentVersion, forKey: "lastShownWelcomeVersion")
            return true
        }

        // 比较版本
        let shouldShow = isSignificantVersionUpdate(from: lastVersion, to: currentVersion)

        // 需要显示welcome
        if shouldShow {
            os_log("\(self.t) \(AppDelegate.emoji) 重要版本更新，显示欢迎窗口，并记录当前版本：\(currentVersion)")
            UserDefaults.standard.set(currentVersion, forKey: "lastShownWelcomeVersion")
        }

        return shouldShow
    }

    /**
     * 获取当前应用版本号
     * 从Bundle中读取MARKETING_VERSION
     */
    private func getCurrentAppVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    /**
     * 判断是否为重要版本更新（major或minor）
     * 版本格式：major.minor.patch
     */
    private func isSignificantVersionUpdate(from oldVersion: String, to newVersion: String) -> Bool {
        let oldComponents = parseVersion(oldVersion)
        let newComponents = parseVersion(newVersion)

        // 比较major版本
        if newComponents.major > oldComponents.major {
            return true
        }

        // major版本相同，比较minor版本
        if newComponents.major == oldComponents.major && newComponents.minor > oldComponents.minor {
            return true
        }

        // 只是patch更新，不显示welcome
        return false
    }

    /**
     * 解析版本号字符串
     * 返回(major, minor, patch)元组
     */
    private func parseVersion(_ version: String) -> (major: Int, minor: Int, patch: Int) {
        let components = version.split(separator: ".").compactMap { Int($0) }

        let major = components.count > 0 ? components[0] : 0
        let minor = components.count > 1 ? components[1] : 0
        let patch = components.count > 2 ? components[2] : 0

        return (major, minor, patch)
    }
}
