import Cocoa
import MagicCore
import NetworkExtension
import OSLog
import SwiftUI
import SystemExtensions

@MainActor
final class FirewallService: NSObject, SuperLog, SuperEvent, SuperThread {
    static let shared = FirewallService()

    nonisolated static let emoji = "🛡️"

    private var ipc = IPCConnection.shared
    private var extensionManager = OSSystemExtensionManager.shared
    private var extensionBundle = AppConfig.extensionBundle
    private var error: Error?
    private var observer: Any?
    private let s: AppPermissionService = .shared
    var status: FilterStatus = .stopped

    override private init() {
        super.init()
        os_log("\(Self.onInit)")

        self.emit(.willBoot)
        self.updateFilterStatus(.indeterminate)
        self.setObserver()

        // loadFilterConfiguration 然后 filterManager.isEnabled 才能得到正确的值
        Task {
            do {
                try await loadFilterConfiguration(reason: "Boot")
            } catch {
                os_log(.error, "\(self.t)Boot -> \(error)")
            }

            let isEnabled = NEFilterManager.shared().isEnabled

            os_log("\(self.t)\(isEnabled ? "✅ 过滤器已启用" : "⚠️ 过滤器未启用")")

            updateFilterStatus(isEnabled ? .running : .disabled)
        }
    }

    /// 更新过滤器状态
    /// - Parameter status: 新的过滤器状态
    private func updateFilterStatus(_ status: FilterStatus) {
        let oldValue = self.status

        self.status = status

        os_log("\(self.t)🍋 更新状态 -> \(status.description) 原状态 -> \(oldValue.description)")
        if oldValue.isNotRunning() && status.isRunning() {
            registerWithProvider(reason: "not running -> running")
        }

        self.emit(.FilterStatusChanged, object: status)
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
    private func ifFilterReady() -> Bool {
        os_log("\(self.t)\(Location.did(.IfReady))")

        if NEFilterManager.shared().isEnabled {
            self.updateFilterStatus(.running)

            return true
        } else {
            return false
        }
    }
}

// MARK: Operator

extension FirewallService {
    func clearError() {
        self.error = nil
    }

    func setError(_ error: Error) {
        self.error = error
    }

    func viewWillDisappear() {
        guard let changeObserver = observer else {
            return
        }

        nc.removeObserver(
            changeObserver,
            name: .NEFilterConfigurationDidChange,
            object: NEFilterManager.shared()
        )
    }

    func installFilter() {
        os_log("\(self.t)\(Location.did(.InstallFilter))")

        self.clearError()
        self.emit(.willInstall)

        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            self.updateFilterStatus(.stopped)
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

    func startFilter(reason: String) async throws {
        os_log("\(self.t)🚀 开启过滤器 🐛 \(reason)  ➡️ Current Status: \(self.status.description)")

        self.emit(.willStart)

        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            os_log("\(self.t)extensionBundle.bundleIdentifier 为空")
            self.updateFilterStatus(.stopped)
            return
        }

        // macOS 15， 系统设置 - 网络 - 过滤器，用户能删除过滤器，所以要确保过滤器已加载

        try await loadFilterConfiguration(reason: reason)

        guard !NEFilterManager.shared().isEnabled else {
            os_log("\(self.t)👌 过滤器已启用，直接关联")
            registerWithProvider(reason: reason)
            return
        }

        os_log("\(self.t)🚀 开始激活系统扩展")

        // Start by activating the system extension
        let activationRequest = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: extensionIdentifier, queue: .main)
        activationRequest.delegate = self
        OSSystemExtensionManager.shared.submitRequest(activationRequest)
    }

    func stopFilter(reason: String) async throws {
        os_log("\(self.t)🤚 停止过滤器 🐛 \(reason)")

        self.emit(.willStop)

        guard NEFilterManager.shared().isEnabled else {
            self.updateFilterStatus(.stopped)
            return
        }

        try await loadFilterConfiguration(reason: reason)

        NEFilterManager.shared().isEnabled = false
        try await NEFilterManager.shared().saveToPreferences()

        self.updateFilterStatus(.stopped)
    }
}

// MARK: Content Filter Configuration Management

extension FirewallService {
    private func loadFilterConfiguration(reason: String) async throws {
        os_log("\(self.t)🚩 读取过滤器配置 🐛 \(reason)")

        // You must call this method at least once before calling saveToPreferencesWithCompletionHandler: for the first time after your app launches.
        try await NEFilterManager.shared().loadFromPreferences()
    }

    private func enableFilterConfiguration(reason: String) {
        os_log("\(self.t)🦶 \(Location.did(.EnableFilterConfiguration))")

        self.emit(.configurationChanged)

        guard !NEFilterManager.shared().isEnabled else {
            os_log("\(self.t)FilterManager is Disabled, registerWithProvider")
            return
        }

        Task {
            do {
                try await loadFilterConfiguration(reason: reason)

                os_log("\(self.t)🎉 加载过滤器配置成功")

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
                os_log("\(self.t)🦶 \(Location.did(.SaveToPreferences))")
                NEFilterManager.shared().saveToPreferences { saveError in
                    if let error = saveError {
                        os_log(.error, "\(self.t)授权对话框报错 -> \(error.localizedDescription)")
                        self.updateFilterStatus(.disabled)
                        return
                    } else {
                        os_log("\(self.t)🦶 \(Location.did(.UserApproved))")
                    }

                    self.registerWithProvider(reason: "已授权")
                }
            } catch {
                os_log("\(self.t)APP: 加载过滤器配置失败")
                self.updateFilterStatus(.stopped)
            }
        }
    }

    private func registerWithProvider(reason: String) {
        os_log("\(self.t)🛫 registerWithProvider，让 ChannelProvider 和 Extension 关联起来(\(reason)")

        self.emit(.willRegisterWithProvider)

        ipc.register(withExtension: extensionBundle, delegate: self) { success in
            if success {
                os_log("\(self.t)🎉 ChannelProvider 和 Extension 关联成功")

                NotificationCenter.default.post(name: .didRegisterWithProvider, object: nil)

                self.updateFilterStatus(.running)
            } else {
                os_log("\(self.t)💔 ChannelProvider 和 Extension 关联失败")

                self.updateFilterStatus(.extensionNotReady)
            }
        }
    }
}

// MARK: OSSystemExtensionActivationRequestDelegate

extension FirewallService: OSSystemExtensionRequestDelegate {
    nonisolated func request(
        _ request: OSSystemExtensionRequest,
        didFinishWithResult result: OSSystemExtensionRequest.Result
    ) {
        switch result {
        case .completed:
            os_log("\(self.t)🍋 OSSystemExtensionRequestDelegate -> completed")
        case .willCompleteAfterReboot:
            os_log("\(self.t)🍋 willCompleteAfterReboot")
        @unknown default:
            os_log("\(self.t)\(result.rawValue)")
        }

        DispatchQueue.main.async {
            self.enableFilterConfiguration(reason: "didFinishWithResult")
        }
    }

    nonisolated func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        os_log(.error, "\(self.t)didFailWithError -> \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.setError(error)
            self.updateFilterStatus(.error(error))
        }
        self.emit(.didFailWithError, userInfo: ["error": error])
    }

    nonisolated func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        os_log("\(self.t)🦶 \(Location.did(.RequestNeedsUserApproval))")
        DispatchQueue.main.async {
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

// MARK: AppCommunication

extension FirewallService: AppCommunication {
    nonisolated func extensionLog(_ words: String) {
        let verbose = false

        if verbose {
            os_log("\(self.t)💬 Extension said -> \(words)")
        }
    }

    nonisolated func needApproval() {
        NotificationCenter.default.post(
            name: .NeedApproval,
            object: nil,
            userInfo: nil
        )
    }

    /// 提示用户是否允许网络连接
    /// - Parameters:
    ///   - id: 应用标识符
    ///   - hostname: 主机名
    ///   - port: 端口号
    ///   - direction: 网络流量方向
    ///   - responseHandler: 响应处理回调
    nonisolated func promptUser(id: String, hostname: String, port: String, direction: NETrafficDirection, responseHandler: @escaping (Bool) -> Void) {
        let verbose = false

        // 在主线程上同步执行 shouldAllow 调用
        let shouldAllow = DispatchQueue.main.sync {
            self.s.shouldAllow(id)
        }
        if shouldAllow {
            if verbose {
                os_log("\(self.t)✅ Channel.promptUser 👤 with App -> \(id) -> Allow")
            }
            responseHandler(true)

            DispatchQueue.main.sync {
                NotificationCenter.default.post(name: .NetWorkFilterFlow, object: FlowWrapper(
                    id: id,
                    hostname: hostname,
                    port: port,
                    allowed: true,
                    direction: direction
                ))
            }
        } else {
            if verbose {
                os_log("\(self.t)🈲 Channel.promptUser 👤 with App -> \(id) -> Deny")
            }
            DispatchQueue.main.sync {
                NotificationCenter.default.post(name: .NetWorkFilterFlow, object: FlowWrapper(
                    id: id,
                    hostname: hostname,
                    port: port,
                    allowed: false,
                    direction: direction
                ))
            }
            responseHandler(false)
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 600)
}
