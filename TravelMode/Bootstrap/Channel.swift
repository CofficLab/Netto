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
            event.emitFilterStatusChanged(status)
        }
    }

    func boot() {
        Logger.app.debug("Channel.boot 🛫")
        status = .indeterminate

        loadFilterConfiguration { success in
            guard success else {
                Logger.app.error("Channel.boot 请求加载到系统设置中失败")
                self.status = .stopped
                return
            }
            
            Logger.app.info("加载配置成功 🎉🎉🎉")

            self.updateStatus()

            Logger.app.info("Channel.boot 添加监听")
            self.observer = NotificationCenter.default.addObserver(
                forName: .NEFilterConfigurationDidChange,
                object: self.filterManager,
                queue: .main
            ) { _ in
                Logger.app.debug("Channel.NEFilterConfigurationDidChange 🚀")
                self.updateStatus()
            }
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

    func updateStatus() {
        if filterManager.isEnabled {
            Logger.app.debug("Channel.updateStatus.registerWithProvider")
            registerWithProvider()
        } else {
            Logger.app.debug("过滤器未安装")
            status = .notInstalled
        }
    }
    
    func installFilter() {
        Logger.app.debug("安装过滤器")
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
        Logger.app.debug("Channel.开启过滤器")
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
        Logger.app.debug("Channel.enableFilterConfiguration")
        let filterManager = self.filterManager

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

            if filterManager.providerConfiguration == nil {
                let providerConfiguration = NEFilterProviderConfiguration()
                providerConfiguration.filterSockets = true
                providerConfiguration.filterPackets = false
                filterManager.providerConfiguration = providerConfiguration
                if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
                    filterManager.localizedDescription = appName
                }
            }

            // 如果true，加载到系统设置中后就是启动状态
            filterManager.isEnabled = true
            
            // 将过滤器加载到系统设置中
            Logger.app.debug("将要弹出授权对话框")
            filterManager.saveToPreferences { saveError in
                DispatchQueue.main.async {
                    if let error = saveError {
                        os_log("授权对话框报错 -> %@", error.localizedDescription)
                        self.status = .needApproval
                        return
                    } else {
                        Logger.app.debug("用户点击了允许 🎉🎉🎉")
                    }

                    //self.registerWithProvider()
                }
            }
        }
    }

    func registerWithProvider() {
        ipc.register(withExtension: extensionBundle, delegate: self) { success in
            Logger.app.debug("Channel.registerWithProvider -> \(success)")
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
        Logger.app.debug("OSSystemExtensionRequestDelegate -> 需要在系统设置中点击允许运行")
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
