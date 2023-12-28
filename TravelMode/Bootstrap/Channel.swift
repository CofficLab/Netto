import Cocoa
import NetworkExtension
import os.log
import SwiftUI
import SystemExtensions

class Channel: NSObject, ObservableObject {
    var observer: Any?
    var status: FilterStatus = .stopped {
        didSet {
            EventManager().emitFilterStatusChanged(status)
        }
    }

    // Get the Bundle of the system extension.
    lazy var extensionBundle: Bundle = {
        let extensionsDirectoryURL = URL(fileURLWithPath: "Contents/Library/SystemExtensions", relativeTo: Bundle.main.bundleURL)
        let extensionURLs: [URL]
        do {
            extensionURLs = try FileManager.default.contentsOfDirectory(
                at: extensionsDirectoryURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles)
        } catch let error {
            fatalError("Failed to get the contents of \(extensionsDirectoryURL.absoluteString): \(error.localizedDescription)")
        }

        guard let extensionURL = extensionURLs.first else {
            fatalError("Failed to find any system extensions")
        }

        guard let extensionBundle = Bundle(url: extensionURL) else {
            fatalError("Failed to create a bundle with URL \(extensionURL.absoluteString)")
        }

        return extensionBundle
    }()

    func viewWillAppear() {
        status = .indeterminate

        loadFilterConfiguration { success in
            guard success else {
                self.status = .stopped
                return
            }

            self.updateStatus()

            self.observer = NotificationCenter.default.addObserver(forName: .NEFilterConfigurationDidChange,
                                                                   object: NEFilterManager.shared(),
                                                                   queue: .main) { [weak self] _ in
                self?.updateStatus()
            }
        }
    }

    func viewWillDisappear() {
        guard let changeObserver = observer else {
            return
        }

        NotificationCenter.default.removeObserver(changeObserver, name: .NEFilterConfigurationDidChange, object: NEFilterManager.shared())
    }

    // MARK: Update the UI

    func updateStatus() {
        if NEFilterManager.shared().isEnabled {
            registerWithProvider()
        } else {
            status = .stopped
        }
    }

    // MARK: UI Event Handlers

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
                        os_log("Failed to disable the filter configuration: %@", error.localizedDescription)
                        self.status = .running
                        return
                    }

                    self.status = .stopped
                }
            }
        }
    }

    // MARK: Content Filter Configuration Management

    func loadFilterConfiguration(completionHandler: @escaping (Bool) -> Void) {
        Logger.app.debug("loadFilterConfiguration")
        NEFilterManager.shared().loadFromPreferences { loadError in
            DispatchQueue.main.async {
                var success = true
                if let error = loadError {
                    os_log("Failed to load the filter configuration: %@", error.localizedDescription)
                    success = false
                } else {
                    Logger.app.debug("loadFilterConfiguration->no error")
                }
                completionHandler(success)
            }
        }
    }

    func enableFilterConfiguration() {
        Logger.app.debug("enableFilterConfiguration")
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
                        os_log("enableFilterConfiguration->Failed to save the filter configuration: %@", error.localizedDescription)
                        self.status = .stopped
                        return
                    }

                    self.registerWithProvider()
                }
            }
        }
    }

    // MARK: ProviderCommunication

    func registerWithProvider() {
        Logger.app.debug("registerWithProvider")
        IPCConnection.shared.register(withExtension: extensionBundle, delegate: self) { success in
            DispatchQueue.main.async {
                self.status = (success ? .running : .stopped)
            }
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
    func needApproval() {
        EventManager().emitNeedApproval()
    }
    
    // MARK: AppCommunication

    func promptUser(flow: NEFilterFlow, responseHandler: @escaping (Bool) -> Void) {
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
