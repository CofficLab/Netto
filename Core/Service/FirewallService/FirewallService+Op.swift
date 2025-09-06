import Foundation
import NetworkExtension
import OSLog
import SystemExtensions

// MARK: Operator

extension FirewallService {
    func clearError() {
        self.error = nil
    }

    func setError(_ error: Error) {
        self.error = error
    }

    func removeObserver() {
        guard let changeObserver = observer else {
            return
        }

        nc.removeObserver(
            changeObserver,
            name: .NEFilterConfigurationDidChange,
            object: NEFilterManager.shared()
        )
    }

    /// 检查APP是否安装在Applications目录
    /// - Returns: 如果APP安装在Applications目录返回true，否则返回false
    func isAppInApplicationsFolder() -> Bool {
        guard let appPath = Bundle.main.bundlePath as String? else {
            os_log("\(self.t)无法获取APP路径")
            return false
        }
        
        let applicationsPath = "/Applications"
        let isInApplications = appPath.hasPrefix(applicationsPath)
        
        return isInApplications
    }

    func activateSystemExtension() {
        os_log("\(self.t)🚀 开始激活系统扩展")

        // 检查APP是否安装在Applications目录
        guard isAppInApplicationsFolder() else {
            os_log("\(self.t)❌ APP未安装在Applications目录，无法激活系统扩展")
            Task { @MainActor in
                self.updateFilterStatus(.notInApplicationsFolder)
            }
            return
        }

        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            os_log("\(self.t)extensionBundle.bundleIdentifier 为空")
            Task { @MainActor in
                self.updateFilterStatus(.stopped)
            }
            return
        }

        // Start by activating the system extension
        let activationRequest = OSSystemExtensionRequest.activationRequest(
            forExtensionWithIdentifier: extensionIdentifier,
            queue: .main
        )
        activationRequest.delegate = self
        extensionManager.submitRequest(activationRequest)
    }

    func installFilter() {
        self.clearError()
        self.emit(.firewallWillInstall)
        self.activateSystemExtension()
    }

    func startFilter(reason: String) async throws {
        os_log("\(self.t)🚀 开启过滤器 🐛 \(reason)  ➡️ Current Status: \(self.status.description)")

        self.emit(.firewallWillStart)

        guard !NEFilterManager.shared().isEnabled else {
            os_log("\(self.t)👌 过滤器已启用")
            self.emit(.firewallDidStart)
            return
        }

        self.activateSystemExtension()
    }

    func stopFilter(reason: String) async throws {
        os_log("\(self.t)🤚 停止过滤器 🐛 \(reason)")

        self.emit(.firewallWillStop)

        guard NEFilterManager.shared().isEnabled else {
            await self.updateFilterStatus(.stopped)
            return
        }

        NEFilterManager.shared().isEnabled = false
        try await NEFilterManager.shared().saveToPreferences()
    }
}
