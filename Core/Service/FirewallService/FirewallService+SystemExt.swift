import Foundation
import NetworkExtension
import OSLog
import SwiftUI
import SystemExtensions

// MARK: - 系统扩展相关操作

// 系统扩展：指的是系统设置 - 通用 - 登录项与扩展 - 网络扩展

extension FirewallService {
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

    /// 激活系统扩展，会发出请求
    func activateSystemExtension() {
        os_log("\(self.t)🚀 开始激活系统扩展")

        // 检查APP是否安装在Applications目录
        guard isAppInApplicationsFolder() else {
            os_log("\(self.t)❌ APP未安装在Applications目录，无法激活系统扩展")
            Task { @MainActor in
                self.updateStatus(.notInApplicationsFolder)
            }
            return
        }

        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            os_log("\(self.t)extensionBundle.bundleIdentifier 为空")
            Task { @MainActor in
                self.updateStatus(.stopped)
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

    /// 取消激活系统扩展，会发出请求
    func deactivateSystemExtension() {
        os_log("\(self.t)🚀 开始取消激活系统扩展")
        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            os_log("\(self.t)extensionBundle.bundleIdentifier 为空")
            return
        }

        let deactivationRequest = OSSystemExtensionRequest.deactivationRequest(
            forExtensionWithIdentifier: extensionIdentifier,
            queue: .main
        )
        deactivationRequest.delegate = self
        extensionManager.submitRequest(deactivationRequest)
    }

    /// 请求系统扩展的状态，会发出请求
    func requestSystemExtensionStatus() {
        os_log("\(self.t)🚀 开始请求系统扩展的状态")
        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            os_log("\(self.t)extensionBundle.bundleIdentifier 为空")
            Task { @MainActor in
                self.updateStatus(.stopped)
            }
            return
        }

        let propertiesRequest = OSSystemExtensionRequest.propertiesRequest(
            forExtensionWithIdentifier: extensionIdentifier,
            queue: .main
        )
        propertiesRequest.delegate = self
        extensionManager.submitRequest(propertiesRequest)
    }

    /// 安装系统扩展，会发出请求
    func installExtension() {
        os_log("\(self.t)🚀 开始安装扩展")
        self.clearError()
        self.emit(.firewallWillInstall)
        self.activateSystemExtension()
    }

    /// 获取系统扩展的标识符
    func getExtensionIdentifier() -> String {
        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            os_log("\(self.t)extensionBundle.bundleIdentifier 为空")
            return ""
        }
        return extensionIdentifier
    }

    /// 获取当前app对应的系统扩展版本信息
    func getCurrentExtensionVersion() -> (version: String, shortVersion: String, identifier: String)? {
        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            os_log("\(self.t)extensionBundle.bundleIdentifier 为空")
            return nil
        }

        guard let version = extensionBundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
            os_log("\(self.t)extensionBundle CFBundleVersion 为空")
            return nil
        }

        guard let shortVersion = extensionBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            os_log("\(self.t)extensionBundle CFBundleShortVersionString 为空")
            return nil
        }

        os_log("\(self.t)📱 当前app带有的系统扩展版本信息:")
        os_log("\(self.t)  - 标识符: \(extensionIdentifier)")
        os_log("\(self.t)  - 版本号: \(version)")
        os_log("\(self.t)  - 短版本: \(shortVersion)")

        return (version: version, shortVersion: shortVersion, identifier: extensionIdentifier)
    }
}

// MARK: - 接收系统扩展相关操作的结果

// 系统扩展：指的是系统设置 - 通用 - 登录项与扩展 - 网络扩展
extension FirewallService: OSSystemExtensionRequestDelegate {
    /// 接收系统扩展的激活结果
    func request(
        _ request: OSSystemExtensionRequest,
        didFinishWithResult result: OSSystemExtensionRequest.Result
    ) {
        switch result {
        case .completed:
            os_log("\(self.t)✅ 收到结果：系统扩展已激活")
            self.emit(.extensionDidInstall)

            // 更新系统状态
            if self.status.isExtensionNotActivated() {
                Task {
                    await self.updateStatus(.stopped)
                }
            }
        case .willCompleteAfterReboot:
            os_log("\(self.t)✅ 收到结果：系统扩展将在重启后激活")
        @unknown default:
            os_log("\(self.t)\(result.rawValue)")
        }
    }

    /// 接收系统扩展的激活失败结果
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        os_log(.error, "\(self.t)didFailWithError -> \(error.localizedDescription)")

        self.setError(error)
        Task { @MainActor in
            self.updateStatus(.error(error))
        }

        self.emit(.firewallDidFailWithError, userInfo: ["error": error])
    }

    /// 接收系统扩展的用户授权请求
    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        os_log("\(self.t)🙆 需要用户同意激活系统扩展")
        Task { @MainActor in
            self.updateStatus(.needSystemExtensionApproval)
        }
    }

    /// 接收系统扩展的属性请求
    func request(_ request: OSSystemExtensionRequest, foundProperties properties: [OSSystemExtensionProperties]) {
        os_log("\(self.t)🔔 收到了系统扩展的属性请求结果")

        // 获取当前app的系统扩展版本信息
        guard let currentVersion = getCurrentExtensionVersion() else {
            os_log("\(self.t)❌ 无法获取当前app的系统扩展版本信息")
            return
        }

        // 查找当前版本的扩展是否已安装
        var currentVersionInstalled: OSSystemExtensionProperties?
        var latestVersion: String = ""
        var latestProperty: OSSystemExtensionProperties?

        // 输出详细的系统扩展属性信息
        for property in properties {
            if property.isUninstalling {
                continue
            }

            os_log("\(self.t)📦 已安装的系统扩展信息:")
            os_log("\(self.t)  - 包标识符: \(property.bundleIdentifier)")
            os_log("\(self.t)  - 版本号: \(property.bundleVersion)")
            os_log("\(self.t)  - 文件路径: \(property.url.path)")
            os_log("\(self.t)  - 是否启用: \(property.isEnabled ? "✅" : "❌")")
            os_log("\(self.t)  - 等待用户授权: \(property.isAwaitingUserApproval ? "✅" : "❌")")

            // 检查是否是当前版本的扩展
            if property.bundleVersion == currentVersion.version {
                currentVersionInstalled = property
            }

            // 比较版本号，记录最新的
            if property.bundleVersion > latestVersion {
                latestVersion = property.bundleVersion
                latestProperty = property
            }
        }

        // 输出版本安装状态信息
        os_log("\(self.t)🏆 版本安装状态:")
        os_log("\(self.t)  - 当前app版本: \(currentVersion.version) (\(currentVersion.shortVersion))")

        if let currentInstalled = currentVersionInstalled {
            os_log("\(self.t)  - 当前版本状态: ✅ 已安装")
            os_log("\(self.t)  - 安装路径: \(currentInstalled.url.path)")
            os_log("\(self.t)  - 启用状态: \(currentInstalled.isEnabled ? "✅" : "❌")")
            os_log("\(self.t)  - 等待授权: \(currentInstalled.isAwaitingUserApproval ? "✅" : "❌")")
            os_log("\(self.t)  - 正在卸载: \(currentInstalled.isUninstalling ? "✅" : "❌")")

            var status = self.status
            if currentInstalled.isEnabled == false {
                status = .extensionNotActivated
            }

            if currentInstalled.isUninstalling {
                status = .systemExtensionNotInstalled
            }

            Task {
                await self.updateStatus(status)
            }
        } else {
            os_log("\(self.t)  - 当前版本状态: ❌ 未安装")

            if let latest = latestProperty {
                os_log("\(self.t)  - 已安装版本: \(latest.bundleVersion) (\(latest.bundleShortVersion))")
                os_log("\(self.t)  - 版本差异: 当前版本未安装，但有其他版本已安装")
                
                // 当前版本未安装，但有其他版本已安装，设置为需要更新状态
                Task {
                    await self.updateStatus(.systemExtensionNeedUpdate)
                }
            } else {
                os_log("\(self.t)  - 版本差异: 当前版本未安装，且无其他版本")
                
                // 当前版本未安装，且无其他版本，设置为未安装状态
                Task {
                    await self.updateStatus(.systemExtensionNotInstalled)
                }
            }
        }
    }

    /// 接收系统扩展的替换请求
    nonisolated func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension newExtension: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        os_log("\(self.t)🔄 系统扩展替换请求:")
        os_log("\(self.t)  - 现有扩展: \(existing.bundleIdentifier) v\(existing.bundleVersion)")
        os_log("\(self.t)  - 新扩展: \(newExtension.bundleIdentifier) v\(newExtension.bundleVersion)")

        os_log("\(self.t)  - 现有扩展状态: 启用=\(existing.isEnabled ? "是" : "否"), 等待授权=\(existing.isAwaitingUserApproval ? "是" : "否")")
        os_log("\(self.t)  - 新扩展状态: 启用=\(newExtension.isEnabled ? "是" : "否"), 等待授权=\(newExtension.isAwaitingUserApproval ? "是" : "否")")

        os_log("\(self.t)  - 决定: 替换现有扩展")
        return .replace
    }
}

// MARK: - Preview

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(width: 700)
}
