import Cocoa
import NetworkExtension
import os.log
import SwiftUI
import SystemExtensions

class Channel: NSObject, ObservableObject {
    private var event = EventManager()
    private var ipc = IPCConnection.shared
    private var filterManager = NEFilterManager.shared()
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
                self.status = .stopped
                return
            }

            self.updateStatus()

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
        Logger.app.debug("Channel.updateStatus")
        if filterManager.isEnabled {
            Logger.app.debug("Channel.updateStatus.registerWithProvider")
            registerWithProvider()
        } else {
            Logger.app.debug("Channel.updateStatus->stopped")
            status = .stopped
        }
    }

    func startFilter() {
        Logger.app.debug("Channel.开启过滤器")
        status = .indeterminate
        guard !NEFilterManager.shared().isEnabled else {
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
        Logger.app.debug("Channel.loadFilterConfiguration")
        NEFilterManager.shared().loadFromPreferences { loadError in
            DispatchQueue.main.async {
                var success = true
                if let error = loadError {
                    os_log("Failed to load the filter configuration: %@", error.localizedDescription)
                    success = false
                } else {
                    // 此时请求授权的对话框已经显示了
                    Logger.app.debug("Channel.loadFromPreferences->success")
                    self.status = .waitingForApproval
                }
                
                completionHandler(success)
            }
        }
    }

    func enableFilterConfiguration() {
        Logger.app.debug("Channel.enableFilterConfiguration")
        let filterManager = NEFilterManager.shared()

        guard !filterManager.isEnabled else {
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
            filterManager.saveToPreferences { saveError in
                DispatchQueue.main.async {
                    if let error = saveError {
                        os_log("Channel.enableFilterConfiguration->%@", error.localizedDescription)
                        self.status = .rejected
                        return
                    }

                    self.registerWithProvider()
                }
            }
        }
    }

    func registerWithProvider() {
        ipc.register(withExtension: extensionBundle, delegate: self) { success in
            Logger.app.debug("Channel.registerWithProvider->\(success)")
            self.status = success ? .running : .stopped
        }
    }
}

// MARK: OSSystemExtensionActivationRequestDelegate

extension Channel: OSSystemExtensionRequestDelegate {
    // 调起授权请求后
    func request(
        _ request: OSSystemExtensionRequest,
        didFinishWithResult result: OSSystemExtensionRequest.Result
    ) {
        Logger.app.debug("Channel.didFinishWithResult->\(String(describing: result))")
        
        guard result == .completed else {
            os_log("Unexpected result %d for system extension request", result.rawValue)
            status = .stopped
            return
        }

        enableFilterConfiguration()
    }

    func request(
        _ request: OSSystemExtensionRequest,
        didFailWithError error: Error
    ) {
        Logger.app.debug("Channel.didFailWithError->\(error.localizedDescription)")
        
        status = .stopped
    }

    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        Logger.app.debug("Channel.requestNeedsUserApproval")
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
