import Cocoa
import MagicKit
import NetworkExtension
import OSLog
import SwiftUI
import SystemExtensions

class ChannelProvider: NSObject, ObservableObject, SuperLog {
    let emoji = "🫙"

    private var event = EventManager()
    private var ipc = IPCConnection.shared
    private var filterManager = NEFilterManager.shared()
    private var extensionManager = OSSystemExtensionManager.shared
    private var extensionBundle = AppConfig.extensionBundle
    
    @Published var error: Error?

    var observer: Any?
    var status: FilterStatus = .stopped {
        didSet {
            if oldValue.isRunning() == false && status.isRunning() {
                registerWithProvider()
            }

            event.emitFilterStatusChanged(status)
        }
    }

    func boot() {
        os_log("\(self.t)\(Location.did(.Boot))")
        self.status = .indeterminate
        self.setObserver()

        os_log("\(self.t)\(Location.did(.IfReady))")
        // loadFilterConfiguration 然后 filterManager.isEnabled 才能得到正确的值
        loadFilterConfiguration { _ in
            if self.filterManager.isEnabled {
                self.status = .running
            } else {
                // 扩展未启用，有两种情况
                // 1. 未安装
                // 2. 安装了但未启用
                self.status = .notInstalled
            }
        }
    }

    func clearError() {
        self.error = nil
    }

    func setError(_ error: Error) {
        self.error = error
    }

    func setObserver() {
        // Logger.app.info("APP: 添加监听")
        observer = NotificationCenter.default.addObserver(
            forName: .NEFilterConfigurationDidChange,
            object: filterManager,
            queue: .main
        ) { _ in
            let enabled = self.filterManager.isEnabled
            os_log("\(self.t)Observer: \(enabled ? "扩展已打开" : "扩展已关闭") 🚀")
            self.status = self.filterManager.isEnabled ? .running : .stopped
        }
    }

    // 过滤器是否已经启动了
    func ifFilterReady(completionHandler: @escaping (Bool) -> Void) {
        os_log("\(self.t)\(Location.did(.IfReady))")

        if filterManager.isEnabled {
            registerWithProvider()
            status = .running

            completionHandler(true)
        } else {
            completionHandler(false)
        }
    }

    func viewWillDisappear() {
        guard let changeObserver = observer else {
            return
        }

        NotificationCenter.default.removeObserver(changeObserver,
                                                  name: .NEFilterConfigurationDidChange,
                                                  object: filterManager
        )
    }

//    func updateStatus() {
//        if filterManager.isEnabled {
//            os_log("\(self.t)APP: updateStatus.registerWithProvider")
//            registerWithProvider()
//        } else {
//            os_log("\(self.t)APP: 过滤器未启用")
//            status = .notInstalled
//        }
//    }

    func installFilter() {
        os_log("\(self.t)\(Location.did(.InstallFilter))")
        
        self.clearError()
        
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

    func startFilter() {
        os_log("\(self.t)APP: 开启过滤器")
        status = .indeterminate
        guard !filterManager.isEnabled else {
            registerWithProvider()
            return
        }

        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            status = .stopped
            return
        }

        // Start by activating the system extension
        let activationRequest = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: extensionIdentifier, queue: .main)
        activationRequest.delegate = self
        OSSystemExtensionManager.shared.submitRequest(activationRequest)
    }

    func stopFilter() {
        let filterManager = NEFilterManager.shared()

        status = .indeterminate

        guard filterManager.isEnabled else {
            status = .stopped
            return
        }

        loadFilterConfiguration { success in
            guard success else {
                self.status = .running
                return
            }

            // Disable the content filter configuration
            filterManager.isEnabled = false
            filterManager.saveToPreferences { saveError in
                DispatchQueue.main.async {
                    if let error = saveError {
                        os_log("saveToPreferences: %@", error.localizedDescription)
                        self.status = .stopped
                        return
                    }

                    self.status = .stopped
                }
            }
        }
    }

    // MARK: Content Filter Configuration Management

    func loadFilterConfiguration(completionHandler: @escaping (Bool) -> Void) {
        os_log("\(self.t)\(Location.did(.LoadFilterConfiguration))")
        // You must call this method at least once before calling saveToPreferencesWithCompletionHandler: for the first time after your app launches.
        filterManager.loadFromPreferences { loadError in
            DispatchQueue.main.async {
                var success = true
                if let error = loadError {
                    Logger.app.error("\(error.localizedDescription)")
                    success = false
                } else {
                    self.status = .waitingForApproval
                }

                completionHandler(success)
            }
        }
    }

    func enableFilterConfiguration() {
        os_log("\(self.t)\(Location.did(.EnableFilterConfiguration))")
        guard !filterManager.isEnabled else {
            os_log("\(self.t)FilterManager is Disabled, registerWithProvider")
            registerWithProvider()
            return
        }

        loadFilterConfiguration { success in
            guard success else {
                self.status = .stopped
                return
            }

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
            // os_log("\(self.t)APP: 将要弹出授权对话框")
            os_log("\(self.t)\(Location.did(.SaveToPreferences))")
            self.filterManager.saveToPreferences { saveError in
                DispatchQueue.main.async {
                    if let error = saveError {
                        os_log("授权对话框报错 -> %@", error.localizedDescription)
                        self.status = .needApproval
                        return
                    } else {
                        os_log("\(self.t)\(Location.did(.UserApproved))")
                    }

                    // self.registerWithProvider()
                }
            }
        }
    }

    func registerWithProvider() {
        os_log("\(self.t)APP: registerWithProvider，让 APP 和 Provider 关联起来")
        ipc.register(withExtension: extensionBundle, delegate: self) { success in
            os_log("\(self.t)APP: 和 Provider 关联成功")
            self.status = success ? .running : .stopped
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

        enableFilterConfiguration()
    }

    func request(
        _ request: OSSystemExtensionRequest,
        didFailWithError error: Error
    ) {
        os_log(.error, "\(self.t)didFailWithError -> \(error.localizedDescription)")
        setError(error)

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
        Logger.app.info("Provider said: \(words)")
    }

    func providerSay(_ words: String) {
        Logger.app.info("Provider: \(words)")
    }

    func needApproval() {
        EventManager().emitNeedApproval()
    }

    // MARK: AppCommunication

    func promptUser(flow: NEFilterFlow, responseHandler: @escaping (Bool) -> Void) {
        // Logger.app.info("Channel.promptUser")
        DispatchQueue.main.async {
            if AppSetting.shouldAllow(flow.getAppId()) {
                EventManager().emitNetworkFilterFlow(flow, allowed: true)
                responseHandler(true)
            } else {
                EventManager().emitNetworkFilterFlow(flow, allowed: false)
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
