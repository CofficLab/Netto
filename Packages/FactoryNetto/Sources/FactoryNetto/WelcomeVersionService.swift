import Foundation
import OSLog

/**
 * 版本服务，处理应用版本相关的逻辑
 * 包括版本比较、版本更新检查等功能
 */
final class VersionService {
    private static let emoji = "🏷️"
    
    // MARK: - Properties
    
    /// 用于存储上次显示欢迎窗口的版本号的键
    private let lastShownVersionKey = "lastShownWelcomeVersion"
    
    // MARK: - Public Methods
    
    /**
     * 判断是否应该显示欢迎窗口
     * 基于版本比较逻辑：
     * - 首次安装：显示
     * - patch版本更新（x.y.z -> x.y.z+1）：不显示
     * - minor版本更新（x.y.z -> x.y+1.0）：显示
     * - major版本更新（x.y.z -> x+1.0.0）：显示
     */
    func shouldShowWelcomeWindow() -> Bool {
        let lastShownVersion = UserDefaults.standard.string(forKey: lastShownVersionKey)
        let currentVersion = getCurrentAppVersion()

        os_log("\(Self.emoji)🆚 last: \(lastShownVersion ?? "nil"), current: \(currentVersion)")

        // 首次安装或无法获取版本信息
        guard let lastVersion = lastShownVersion, !lastVersion.isEmpty else {
            // 记录当前版本
            os_log("\(Self.emoji) 首次安装，显示欢迎窗口，并记录当前版本：\(currentVersion)")
            UserDefaults.standard.set(currentVersion, forKey: lastShownVersionKey)
            return true
        }

        // 比较版本
        let shouldShow = isSignificantVersionUpdate(from: lastVersion, to: currentVersion)

        // 需要显示welcome
        if shouldShow {
            os_log("\(Self.emoji) 重要版本更新，显示欢迎窗口，并记录当前版本：\(currentVersion)")
            UserDefaults.standard.set(currentVersion, forKey: lastShownVersionKey)
        }

        return shouldShow
    }
    
    /**
     * 获取当前应用版本号
     * 从Bundle中读取MARKETING_VERSION
     */
    func getCurrentAppVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    
    /**
     * 判断是否为重要版本更新（major或minor）
     * 版本格式：major.minor.patch
     */
    func isSignificantVersionUpdate(from oldVersion: String, to newVersion: String) -> Bool {
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
    func parseVersion(_ version: String) -> (major: Int, minor: Int, patch: Int) {
        let components = version.split(separator: ".").compactMap { Int($0) }

        let major = components.count > 0 ? components[0] : 0
        let minor = components.count > 1 ? components[1] : 0
        let patch = components.count > 2 ? components[2] : 0

        return (major, minor, patch)
    }
}
