import Cocoa
import NetworkExtension
import SystemExtensions
import os.log
import SwiftUI

class Channel: NSViewController {

    enum Status {
        case stopped
        case indeterminate
        case running
    }

    // MARK: Properties

    @IBOutlet var statusIndicator: NSImageView!
    @IBOutlet var statusSpinner: NSProgressIndicator!
    @IBOutlet var startButton: NSButton!
    @IBOutlet var stopButton: NSButton!
    @IBOutlet var logTextView: NSTextView!

    var observer: Any?

    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    var status: Status = .stopped

    // Get the Bundle of the system extension.
    lazy var extensionBundle: Bundle = {
        let extensionsDirectoryURL = URL(fileURLWithPath: "Contents/Library/SystemExtensions", relativeTo: Bundle.main.bundleURL)
        let extensionURLs: [URL]
        do {
            extensionURLs = try FileManager.default.contentsOfDirectory(at: extensionsDirectoryURL,
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

    // MARK: NSViewController

    override func viewWillAppear() {
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

    override func viewWillDisappear() {
        super.viewWillDisappear()

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
        Logger.app.debug("开启过滤器")
        status = .indeterminate
        Event().emitFilterStatusChanged(.indeterminate)
        guard !NEFilterManager.shared().isEnabled else {
            registerWithProvider()
            return
        }

        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            self.status = .stopped
            Event().emitFilterStatusChanged(.stopped)
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
        Event().emitFilterStatusChanged(.indeterminate)

        guard filterManager.isEnabled else {
            status = .stopped
            Event().emitFilterStatusChanged(.stopped)
            return
        }

        loadFilterConfiguration { success in
            guard success else {
                self.status = .running
                Event().emitFilterStatusChanged(.running)
                return
            }

            // Disable the content filter configuration
            filterManager.isEnabled = false
            filterManager.saveToPreferences { saveError in
                DispatchQueue.main.async {
                    if let error = saveError {
                        os_log("Failed to disable the filter configuration: %@", error.localizedDescription)
                        self.status = .running
                        Event().emitFilterStatusChanged(.running)
                        return
                    }

                    self.status = .stopped
                    Event().emitFilterStatusChanged(.stopped)
                }
            }
        }
    }

    // MARK: Content Filter Configuration Management

    func loadFilterConfiguration(completionHandler: @escaping (Bool) -> Void) {
        os_log("============= %@", "loadFilterConfiguration")
        NEFilterManager.shared().loadFromPreferences { loadError in
            DispatchQueue.main.async {
                var success = true
                if let error = loadError {
                    os_log("Failed to load the filter configuration: %@", error.localizedDescription)
                    success = false
                }
                completionHandler(success)
            }
        }
    }

    func enableFilterConfiguration() {
        os_log("============= %@", "enableFilterConfiguration")
        let filterManager = NEFilterManager.shared()

        guard !filterManager.isEnabled else {
            registerWithProvider()
            return
        }

        loadFilterConfiguration { success in

            guard success else {
                self.status = .stopped
                Event().emitFilterStatusChanged(.stopped)
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

            filterManager.isEnabled = true

            filterManager.saveToPreferences { saveError in
                DispatchQueue.main.async {
                    if let error = saveError {
                        os_log("Failed to save the filter configuration: %@", error.localizedDescription)
                        self.status = .stopped
                        Event().emitFilterStatusChanged(.stopped)
                        return
                    }

                    self.registerWithProvider()
                }
            }
        }
    }

    // MARK: ProviderCommunication

    func registerWithProvider() {
        os_log("============= %@", "registerWithProvider")
        IPCConnection.shared.register(withExtension: extensionBundle, delegate: self) { success in
            DispatchQueue.main.async {
                self.status = (success ? .running : .stopped)
                Event().emitFilterStatusChanged(success ? .running : .stopped)
            }
        }
    }
}

extension Channel: OSSystemExtensionRequestDelegate {

    // MARK: OSSystemExtensionActivationRequestDelegate

    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {

        guard result == .completed else {
            os_log("Unexpected result %d for system extension request", result.rawValue)
            status = .stopped
            Event().emitFilterStatusChanged(.stopped)
            return
        }

        enableFilterConfiguration()
    }

    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {

        os_log("System extension request failed: %@", error.localizedDescription)
        status = .stopped
        Event().emitFilterStatusChanged(.stopped)
    }

    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {

        os_log("Extension %@ requires user approval", request.identifier)
    }

    func request(_ request: OSSystemExtensionRequest,
                 actionForReplacingExtension existing: OSSystemExtensionProperties,
                 withExtension extension: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {

        os_log("Replacing extension %@ version %@ with version %@", request.identifier, existing.bundleShortVersion, `extension`.bundleShortVersion)
        return .replace
    }
}

extension Channel: AppCommunication {
    // MARK: AppCommunication

    func promptUser(flow: NEFilterFlow, responseHandler: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            guard let socketFlow = flow as? NEFilterSocketFlow,
                let remoteEndpoint = socketFlow.remoteEndpoint as? NWHostEndpoint,
                let localEndpoint = socketFlow.localEndpoint as? NWHostEndpoint else {
                    return
            }

            os_log("Got a new flow with local endpoint %@, remote endpoint %@", localEndpoint, remoteEndpoint)

            let flowInfo = [
                FlowInfoKey.localPort.rawValue: localEndpoint.port,
                FlowInfoKey.remoteAddress.rawValue: remoteEndpoint.hostname
            ]
            
            let blackList: [String] = []
            if blackList.contains(flowInfo["localPort"] ?? "") {
                Event().emitNetworkFilterFlow(flow, allowed: false)
                responseHandler(false)
            } else {
                Event().emitNetworkFilterFlow(flow, allowed: true)
                responseHandler(true)
            }
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
