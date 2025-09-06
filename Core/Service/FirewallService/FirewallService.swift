import Cocoa
import MagicCore
import NetworkExtension
import OSLog
import SwiftUI
import SystemExtensions

final class FirewallService: NSObject, ObservableObject, SuperLog, SuperEvent, SuperThread, @unchecked Sendable {
    nonisolated static let emoji = "🛡️"

    var ipc = IPCConnection.shared
    var extensionManager = OSSystemExtensionManager.shared
    var extensionBundle = ExtensionConfig.extensionBundle
    var error: Error?
    var observer: Any?
    @Published var status: FilterStatus = .indeterminate

    init(repo: AppSettingRepo) async {
        os_log("\(Self.onInit)")

        super.init()

        self.emit(.firewallWillBoot)
        self.setObserver()

        let isEnabled = NEFilterManager.shared().isEnabled

        os_log("\(self.t)\(isEnabled ? "✅ 过滤器已启用" : "⚠️ 过滤器未启用")")

        await updateFilterStatus(isEnabled ? .running : .disabled)
    }

    /// 更新过滤器状态
    /// - Parameter status: 新的过滤器状态
    @MainActor
    func updateFilterStatus(_ status: FilterStatus) {
        if self.status == status { return }

        let oldValue = self.status

        self.status = status

        os_log("\(self.t)🍋 更新状态 \(oldValue.description) -> \(status.description)")

        // 发送状态变化事件
        self.emit(.firewallStatusChanged, object: status)
        
        // 根据状态发送特定事件
        switch status {
        case .running:
            self.emit(.firewallDidStart)
        case .stopped:
            self.emit(.firewallDidStop)
        case .error:
            // 错误事件已在其他地方发送
            break
        default:
            break
        }
    }

    private func setObserver() {
        os_log("\(self.t)👀 添加监听")
        observer = nc.addObserver(
            forName: .NEFilterConfigurationDidChange,
            object: NEFilterManager.shared(),
            queue: .main
        ) { _ in
            let enabled = NEFilterManager.shared().isEnabled
            os_log("\(self.t)\(enabled ? "👀 监听到 Filter 已打开 " : "👀 监听到 Fitler 已关闭")")

            Task {
                await self.updateFilterStatus(enabled ? .running : .stopped)
            }
        }
    }

    /// 过滤器是否已经启动了
    @MainActor private func ifFilterReady() -> Bool {
        if NEFilterManager.shared().isEnabled {
            self.updateFilterStatus(.running)

            return true
        } else {
            return false
        }
    }
}

// MARK: Content Filter Configuration Management

extension FirewallService {
    private func enableFilterConfiguration(reason: String) async {
        self.emit(.firewallConfigurationChanged)

        guard !NEFilterManager.shared().isEnabled else {
            os_log("\(self.t)FilterManager is Disabled, registerWithProvider")
            return
        }
        
        do {
            os_log("\(self.t)🚀 请求用户授权")

            if NEFilterManager.shared().providerConfiguration == nil {
                let providerConfiguration = NEFilterProviderConfiguration()
                providerConfiguration.filterSockets = true
                providerConfiguration.filterPackets = false
                NEFilterManager.shared().providerConfiguration = providerConfiguration
                if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
                    NEFilterManager.shared().localizedDescription = appName
                }
            }

            // 如果true，加载到系统设置中后就是启动状态
            NEFilterManager.shared().isEnabled = true

            // 将过滤器加载到系统设置中
            os_log("\(self.t)📺 将要弹出授权对话框来加载到系统设置中")
            try await NEFilterManager.shared().saveToPreferences()
            os_log("\(self.t)🎉 用户授权成功")
            self.emit(.firewallUserApproved)
        } catch {
            os_log(.error, "\(self.t)❌ 请求用户授权失败 -> \(error.localizedDescription)")
            await self.updateFilterStatus(.needApproval)
        }
    }
}

// MARK: OSSystemExtensionActivationRequestDelegate

extension FirewallService: OSSystemExtensionRequestDelegate {
    func request(
        _ request: OSSystemExtensionRequest,
        didFinishWithResult result: OSSystemExtensionRequest.Result
    ) {
        switch result {
        case .completed:
            os_log("\(self.t)✅ 系统扩展已激活")
            self.emit(.firewallDidInstall)
        case .willCompleteAfterReboot:
            os_log("\(self.t)🍋 willCompleteAfterReboot")
        @unknown default:
            os_log("\(self.t)\(result.rawValue)")
        }

        Task {
            await self.enableFilterConfiguration(reason: "已请求系统扩展")
        }
    }

    nonisolated func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        os_log(.error, "\(self.t)didFailWithError -> \(error.localizedDescription)")

        self.setError(error)
        Task { @MainActor in
            self.updateFilterStatus(.error(error))
        }

        self.emit(.firewallDidFailWithError, userInfo: ["error": error])
    }

    nonisolated func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        os_log("\(self.t)🙆 需要用户同意")
        Task { @MainActor in
            self.updateFilterStatus(.needApproval)
        }
    }

    nonisolated func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension extension: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        os_log("\(self.t)actionForReplacingExtension")

        return .replace
    }
}

// MARK: - Preview

#Preview("App - Large") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 600, height: 1000)
}

#Preview("App - Small") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 600, height: 600)
}
