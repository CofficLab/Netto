import Cocoa
import MagicCore
import NetworkExtension
import OSLog
import SwiftUI
import SystemExtensions

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

    static let emoji = "📢"

    private var ipc = IPCConnection.shared
    private var filterManager = NEFilterManager.shared()
    private var extensionManager = OSSystemExtensionManager.shared
    private var extensionBundle = AppConfig.extensionBundle

    @Published var error: Error?
    @Published var status: FilterStatus = .stopped {
        didSet {
            if oldValue.isRunning() == false && status.isRunning() {
                registerWithProvider()
            }

            NotificationCenter.default.post(
                name: .FilterStatusChanged,
                object: status,
                userInfo: nil
            )
        }
    }

    var observer: Any?

    /// 更新过滤器状态
    /// - Parameter status: 新的过滤器状态
    @MainActor
    private func updateFilterStatus(_ status: FilterStatus) {
        os_log("\(self.t)🍋 更新状态 -> \(status.description)")
        self.status = status
    }

    func clearError() {
        self.error = nil
    }

    func setError(_ error: Error) {
        self.error = error
    }

    func setObserver() {
        os_log("\(self.t)👀 添加监听")
        observer = nc.addObserver(
            forName: .NEFilterConfigurationDidChange,
            object: filterManager,
            queue: .main
        ) { _ in
            let enabled = self.filterManager.isEnabled
            os_log("\(self.t)\(enabled ? "Filter 已打开 🎉" : "Fitler 已关闭 ❎")")
            self.status = self.filterManager.isEnabled ? .running : .stopped
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
        os_log("\(self.t)开启过滤器 🐛 \(reason)  ➡️ Current Status: \(self.status.description)")

        self.emit(.willStart)

        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            os_log("\(self.t)extensionBundle.bundleIdentifier 为空")
            status = .stopped
            return
        }

        // macOS 15， 系统设置 - 网络 - 过滤器，用户能删除过滤器，所以要确保过滤器已加载

        try await loadFilterConfiguration(reason: reason)

        guard !filterManager.isEnabled else {
            os_log("\(self.t)过滤器已启用，直接关联")
            registerWithProvider()
            return
        }

        os_log("\(self.t)开始激活系统扩展 ⚙️")

        // Start by activating the system extension
        let activationRequest = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: extensionIdentifier, queue: .main)
        activationRequest.delegate = self
        OSSystemExtensionManager.shared.submitRequest(activationRequest)
    }

    func stopFilter(reason: String) async throws {
        os_log("\(self.t)停止过滤器 🐛 \(reason)")

        self.emit(.willStop)

        guard filterManager.isEnabled else {
            status = .stopped
            return
        }

        try await loadFilterConfiguration(reason: reason)

        filterManager.isEnabled = false
        try await filterManager.saveToPreferences()

        await self.updateFilterStatus(.stopped)
    }

    // MARK: Content Filter Configuration Management

    func loadFilterConfiguration(reason: String) async throws {
        os_log("\(self.t)🚩 读取过滤器配置 🐛 \(reason)")

        // You must call this method at least once before calling saveToPreferencesWithCompletionHandler: for the first time after your app launches.
        try await filterManager.loadFromPreferences()
    }

    func enableFilterConfiguration(reason: String) {
        os_log("\(self.t)\(Location.did(.EnableFilterConfiguration))")

        self.emit(.configurationChanged)

        guard !filterManager.isEnabled else {
            os_log("\(self.t)FilterManager is Disabled, registerWithProvider")
            registerWithProvider()
            return
        }

        Task {
            do {
                try await loadFilterConfiguration(reason: reason)

                os_log("\(self.t)加载过滤器配置成功 🎉")

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
                os_log("\(self.t) 📺 将要弹出授权对话框来加载到系统设置中")
                os_log("\(self.t)\(Location.did(.SaveToPreferences))")
                self.filterManager.saveToPreferences { saveError in
                    self.main.async {
                        if let error = saveError {
                            os_log(.error, "\(self.t)授权对话框报错 -> \(error.localizedDescription)")
                            self.status = .disabled
                            return
                        } else {
                            os_log("\(self.t)\(Location.did(.UserApproved))")
                        }

                        self.registerWithProvider()
                    }
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

                self.main.async {
                    self.status = .running
                }
            } else {
                os_log("\(self.t)💔 ChannelProvider 和 Extension 关联失败")

                self.main.async {
                    self.status = .extensionNotReady
                }
            }
        }
    }
}

// MARK: OSSystemExtensionActivationRequestDelegate

extension ChannelProvider: OSSystemExtensionRequestDelegate {
    func request(
        _ request: OSSystemExtensionRequest,
        didFinishWithResult result: OSSystemExtensionRequest.Result
    ) {
        switch result {
        case .completed:
            os_log("\(self.t)OSSystemExtensionRequestDelegate -> completed")
        case .willCompleteAfterReboot:
            os_log("\(self.t)willCompleteAfterReboot")
        @unknown default:
            os_log("\(self.t)\(result.rawValue)")
        }

        enableFilterConfiguration(reason: "didFinishWithResult")
    }

    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        os_log(.error, "\(self.t)didFailWithError -> \(error.localizedDescription)")
        setError(error)
        self.emit(.didFailWithError, userInfo: ["error": error])
        status = .error(error)
    }

    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        os_log("\(self.t)\(Location.did(.RequestNeedsUserApproval))")
        status = .needApproval
    }

    func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension extension: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        os_log("\(self.t)actionForReplacingExtension")

        return .replace
    }
}

extension ChannelProvider: AppCommunication {
    func providerSaid(_ words: String) {
        os_log("\(self.t)💬 Provider said -> \(words)")
    }

    func providerSay(_ words: String) {
        os_log("\(self.t)💬 Provider -> \(words)")
    }

    func needApproval() {
        NotificationCenter.default.post(
            name: .NeedApproval,
            object: nil,
            userInfo: nil
        )
    }

    // MARK: AppCommunication

    func promptUser(flow: NEFilterFlow, responseHandler: @escaping (Bool) -> Void) {
        let verbose = false

        if verbose {
            os_log("\(self.t)Channel.promptUser 👤 with App -> \(flow.getAppId())")
        }

        self.main.async {
            if self.data.shouldAllow(flow.getAppId()) {
                if verbose {
                    os_log("\(self.t)Channel.promptUser 👤 with App -> \(flow.getAppId()) -> Allow")
                }

                self.nc.post(name: .NetWorkFilterFlow, object: FlowWrapper(flow: flow, allowed: true))
                responseHandler(true)
            } else {
                if verbose {
                    os_log("\(self.t)Channel.promptUser 👤 with App -> \(flow.getAppId()) -> Deny")
                }
                self.nc.post(name: .NetWorkFilterFlow, object: FlowWrapper(flow: flow, allowed: false))
                responseHandler(false)
            }
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
