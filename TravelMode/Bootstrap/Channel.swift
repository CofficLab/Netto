import Cocoa
import NetworkExtension
import os.log
import SwiftUI
import SystemExtensions

class Channel: NSObject, ObservableObject {
    private var event = EventManager()
    private var ipc = IPCConnection.shared
    private var filterManager = NEFilterManager.shared()
    private var extensionManager = OSSystemExtensionManager.shared
    private var extensionBundle = ExtConfig.extensionBundle

    var observer: Any?
    var status: FilterStatus = .stopped {
        didSet {
            if status == oldValue {
                return
            }

            if status == .running {
                registerWithProvider()
            }

            event.emitFilterStatusChanged(status)
        }
    }

    func boot() {
        Logger.app.info("\(Location.did(.Boot))")
        self.status = .indeterminate
        self.setObserver()

        Logger.app.info("\(Location.did(.IfReady))")
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
    
    func setObserver() {
        // Logger.app.info("APP: 添加监听")
        observer = NotificationCenter.default.addObserver(
            forName: .NEFilterConfigurationDidChange,
            object: filterManager,
            queue: .main
        ) { _ in
            let enabled = self.filterManager.isEnabled
            Logger.app.debug("Observer: \(enabled ? "扩展已打开" : "扩展已关闭") 🚀")
            self.status = self.filterManager.isEnabled ? .running : .stopped
        }
    }

    // 过滤器是否已经启动了
    func ifFilterReady(completionHandler: @escaping (Bool) -> Void) {
        Logger.app.debug("\(Location.did(.IfReady))")

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
//            Logger.app.debug("APP: updateStatus.registerWithProvider")
//            registerWithProvider()
//        } else {
//            Logger.app.debug("APP: 过滤器未启用")
//            status = .notInstalled
//        }
//    }

    func installFilter() {
        Logger.app.debug("\(Location.did(.InstallFilter))")
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
        Logger.app.debug("APP: 开启过滤器")
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
        Logger.app.info("\(Location.did(.LoadFilterConfiguration))")
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
        Logger.app.debug("\(Location.did(.EnableFilterConfiguration))")
        guard !filterManager.isEnabled else {
            Logger.app.debug("FilterManager is Disabled, registerWithProvider")
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
            // Logger.app.debug("APP: 将要弹出授权对话框")
            Logger.app.debug("\(Location.did(.SaveToPreferences))")
            self.filterManager.saveToPreferences { saveError in
                DispatchQueue.main.async {
                    if let error = saveError {
                        os_log("授权对话框报错 -> %@", error.localizedDescription)
                        self.status = .needApproval
                        return
                    } else {
                        Logger.app.debug("\(Location.did(.UserApproved))")
                    }

                    // self.registerWithProvider()
                }
            }
        }
    }

    func registerWithProvider() {
        Logger.app.debug("APP: registerWithProvider，让 APP 和 Provider 关联起来")
        ipc.register(withExtension: extensionBundle, delegate: self) { success in
            Logger.app.debug("APP: 和 Provider 关联成功")
            self.status = success ? .running : .stopped
        }
    }
}

// MARK: OSSystemExtensionActivationRequestDelegate

extension Channel: OSSystemExtensionRequestDelegate {
    func request(
        _ request: OSSystemExtensionRequest,
        didFinishWithResult result: OSSystemExtensionRequest.Result
    ) {
        switch result {
        case .completed:
            Logger.app.debug("OSSystemExtensionRequestDelegate -> completed")
        case .willCompleteAfterReboot:
            Logger.app.debug("willCompleteAfterReboot")
        @unknown default:
            Logger.app.debug("\(result.rawValue)")
        }

        enableFilterConfiguration()
    }

    func request(
        _ request: OSSystemExtensionRequest,
        didFailWithError error: Error
    ) {
        Logger.app.debug("OSSystemExtensionRequestDelegate -> didFailWithError -> \(error.localizedDescription)")

        status = .stopped
    }

    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        Logger.app.debug("\(Location.did(.RequestNeedsUserApproval))")
        status = .needApproval
    }

    func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension extension: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        Logger.app.debug("actionForReplacingExtension")

        return .replace
    }
}

extension Channel: AppCommunication {
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
