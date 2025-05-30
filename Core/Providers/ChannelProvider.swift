import Cocoa
import MagicCore
import NetworkExtension
import OSLog
import SwiftUI
import SystemExtensions

@MainActor
class ChannelProvider: NSObject, ObservableObject, SuperLog, SuperEvent, SuperThread {
    static let shared = ChannelProvider()

    private var data: DataProvider = DataProvider.shared

    override private init() {
        super.init()
        os_log("\(Self.onInit)")

        self.emit(.willBoot)
        self.status = .indeterminate
        self.setObserver()

        // loadFilterConfiguration 然后 filterManager.isEnabled 才能得到正确的值
        Task {
            do {
                try await loadFilterConfiguration(reason: "Boot")
            } catch {
                os_log(.error, "\(self.t)Boot -> \(error)")
            }

            let isEnabled = self.filterManager.isEnabled

            os_log("\(self.t)\(isEnabled ? "✅ 过滤器已启用" : "⚠️ 过滤器未启用")")

            await updateFilterStatus(isEnabled ? .running : .disabled)
        }
    }

    nonisolated static let emoji = "📢"

    private var ipc = IPCConnection.shared
    @MainActor
    private var filterManager = NEFilterManager.shared()
    private var extensionManager = OSSystemExtensionManager.shared
    private var extensionBundle = AppConfig.extensionBundle

    @Published var error: Error?
    @Published var status: FilterStatus = .stopped

    var observer: Any?

    /// 更新过滤器状态
    /// - Parameter status: 新的过滤器状态
    @MainActor
    private func updateFilterStatus(_ status: FilterStatus) {
        os_log("\(self.t)🍋 更新状态 -> \(status.description)")
        if self.status.isRunning() == false && status.isRunning() {
            registerWithProvider()
        }

        self.status = status

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .FilterStatusChanged,
                object: status,
                userInfo: nil
            )
        }
    }

    func clearError() {
        self.error = nil
    }

    @MainActor
    func setError(_ error: Error) {
        self.error = error
    }

    @MainActor
    func setObserver() {
        os_log("\(self.t)👀 添加监听")
        observer = nc.addObserver(
            forName: .NEFilterConfigurationDidChange,
            object: filterManager,
            queue: .main
        ) { _ in
//            let enabled = self.filterManager.isEnabled
//            os_log("\(self.t)\(enabled ? "👀 监听到 Filter 已打开 " : "👀 监听到 Fitler 已关闭")")
            Task { @MainActor in
                self.updateFilterStatus(self.filterManager.isEnabled ? .running : .stopped)
            }
        }
    }

    // 过滤器是否已经启动了
    func ifFilterReady() -> Bool {
        os_log("\(self.t)\(Location.did(.IfReady))")

        if filterManager.isEnabled {
            registerWithProvider()
            status = .running

            return true
        } else {
            return false
        }
    }

    func viewWillDisappear() {
        guard let changeObserver = observer else {
            return
        }

        nc.removeObserver(changeObserver,
                          name: .NEFilterConfigurationDidChange,
                          object: filterManager
        )
    }

    func installFilter() {
        os_log("\(self.t)\(Location.did(.InstallFilter))")

        self.clearError()
        self.emit(.willInstall)

        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            status = .stopped
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
            status = .stopped
            return
        }

        // macOS 15， 系统设置 - 网络 - 过滤器，用户能删除过滤器，所以要确保过滤器已加载

        try await loadFilterConfiguration(reason: reason)

        guard !filterManager.isEnabled else {
            os_log("\(self.t)👌 过滤器已启用，直接关联")
            registerWithProvider()
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

        guard filterManager.isEnabled else {
            status = .stopped
            return
        }

        try await loadFilterConfiguration(reason: reason)

        filterManager.isEnabled = false
        try await NEFilterManager.shared().saveToPreferences()

        await self.updateFilterStatus(.stopped)
    }

    // MARK: Content Filter Configuration Management

    func loadFilterConfiguration(reason: String) async throws {
        os_log("\(self.t)🚩 读取过滤器配置 🐛 \(reason)")

        // You must call this method at least once before calling saveToPreferencesWithCompletionHandler: for the first time after your app launches.
        try await NEFilterManager.shared().loadFromPreferences()
    }

    func enableFilterConfiguration(reason: String) {
        os_log("\(self.t)🦶 \(Location.did(.EnableFilterConfiguration))")

        self.emit(.configurationChanged)

        guard !filterManager.isEnabled else {
            os_log("\(self.t)FilterManager is Disabled, registerWithProvider")
            registerWithProvider()
            return
        }

        Task {
            do {
                try await loadFilterConfiguration(reason: reason)

                os_log("\(self.t)🎉 加载过滤器配置成功")

                if self.filterManager.providerConfiguration == nil {
                    let providerConfiguration = NEFilterProviderConfiguration()
                    providerConfiguration.filterSockets = true
                    providerConfiguration.filterPackets = false
                    self.filterManager.providerConfiguration = providerConfiguration
                    if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
                        self.filterManager.localizedDescription = appName
                    }
                }

                // 如果true，加载到系统设置中后就是启动状态
                self.filterManager.isEnabled = true

                // 将过滤器加载到系统设置中
                os_log("\(self.t)📺 将要弹出授权对话框来加载到系统设置中")
                os_log("\(self.t)🦶 \(Location.did(.SaveToPreferences))")
                self.filterManager.saveToPreferences { saveError in
//                    self.main.async {
                    if let error = saveError {
                        os_log(.error, "\(self.t)授权对话框报错 -> \(error.localizedDescription)")
                        self.status = .disabled
                        return
                    } else {
                        os_log("\(self.t)🦶 \(Location.did(.UserApproved))")
                    }

                    self.registerWithProvider()
//                    }
                }
            } catch {
                os_log("\(self.t)APP: 加载过滤器配置失败")
                await self.updateFilterStatus(.stopped)
            }
        }
    }

    func registerWithProvider() {
        os_log("\(self.t)🛫 registerWithProvider，让 ChannelProvider 和 Extension 关联起来")

        self.emit(.willRegisterWithProvider)

        ipc.register(withExtension: extensionBundle, delegate: self) { success in
            if success {
                os_log("\(self.t)🎉 ChannelProvider 和 Extension 关联成功")

                self.emit(.didRegisterWithProvider)

//                self.main.async {
//                    self.status = .running
                self.updateFilterStatus(.running)
//                }
            } else {
                os_log("\(self.t)💔 ChannelProvider 和 Extension 关联失败")

//                self.main.async {
                self.status = .extensionNotReady
//                }
            }
        }
    }
}

// MARK: OSSystemExtensionActivationRequestDelegate

extension ChannelProvider: OSSystemExtensionRequestDelegate {
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

extension ChannelProvider: AppCommunication {
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

    nonisolated func promptUser(id: String, hostname: String, port: String, direction: NETrafficDirection, responseHandler: @escaping (Bool) -> Void) {
        let verbose = false

        self.main.async {
//            if self.data.shouldAllow(id) {
//                if verbose {
//                    os_log("\(self.t)✅ Channel.promptUser 👤 with App -> \(flow.getAppId()) -> Allow")
//                }

            self.nc.post(name: .NetWorkFilterFlow, object: FlowWrapper(
                id: id,
                hostname: hostname,
                port: port,

                allowed: true,
                direction: direction
            ))
            responseHandler(true)
//            } else {
            ////                if verbose {
            ////                    os_log("\(self.t)🈲 Channel.promptUser 👤 with App -> \(flow.getAppId()) -> Deny")
            ////                }
//                self.nc.post(name: .NetWorkFilterFlow, object: FlowWrapper(
//                    id: id,
//                    hostname: hostname,
//                    port: port,
//                    allowed: false,
//
//                    direction: direction
//                ))
//                responseHandler(false)
//            }
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
