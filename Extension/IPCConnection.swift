/*
Abstract:
This file contains the implementation of the app <-> provider IPC connection
*/

import Foundation
import OSLog
import Network
import NetworkExtension
import MagicCore

/// App --> Provider IPC
@objc protocol ProviderCommunication {
    func register(_ completionHandler: @escaping (Bool) -> Void)
}

/// Provider --> App IPC
@objc protocol AppCommunication {
    func promptUser(flow: NEFilterFlow, responseHandler: @escaping (Bool) -> Void)
    func needApproval()
    func providerSaid(_ words: String)
}

/// The IPCConnection class is used by both the app and the system extension to communicate with each other
class IPCConnection: NSObject, SuperLog {
    static let emoji = "🤝"
    var listener: NSXPCListener?
    var currentConnection: NSXPCConnection?
    weak var delegate: AppCommunication?
    static let shared = IPCConnection()

    /**
        The NetworkExtension framework registers a Mach service with the name in the system extension's NEMachServiceName Info.plist key.
        The Mach service name must be prefixed with one of the app groups in the system extension's com.apple.security.application-groups entitlement.
        Any process in the same app group can use the Mach service to communicate with the system extension.
     */
    private func extensionMachServiceName(from bundle: Bundle) -> String {
        guard let networkExtensionKeys = bundle.object(forInfoDictionaryKey: "NetworkExtension") as? [String: Any],
            let machServiceName = networkExtensionKeys["NEMachServiceName"] as? String else {
                fatalError("Mach service name is missing from the Info.plist")
        }

        return machServiceName
    }

    func startListener() {
        let machServiceName = extensionMachServiceName(from: Bundle.main)
        os_log("\(self.t)Starting XPC listener for mach service \(machServiceName)")

        let newListener = NSXPCListener(machServiceName: machServiceName)
        newListener.delegate = self
        newListener.resume()
        listener = newListener
    }

    /// This method is called by the app to register with the provider running in the system extension.
    func register(withExtension bundle: Bundle, delegate: AppCommunication, completionHandler: @escaping (Bool) -> Void) {
        self.delegate = delegate

        guard currentConnection == nil else {
            os_log("\(self.t)IPC.register: Already registered with the provider")
            completionHandler(true)
            return
        }
        
        os_log("\(self.t)IPC.register 🛫")

        let machServiceName = extensionMachServiceName(from: bundle)
        let newConnection = NSXPCConnection(machServiceName: machServiceName, options: [])

        // The exported object is the delegate.
        newConnection.exportedInterface = NSXPCInterface(with: AppCommunication.self)
        newConnection.exportedObject = delegate

        // The remote object is the provider's IPCConnection instance.
        newConnection.remoteObjectInterface = NSXPCInterface(with: ProviderCommunication.self)

        currentConnection = newConnection
        newConnection.resume()

        guard let providerProxy = newConnection.remoteObjectProxyWithErrorHandler({ registerError in
            os_log(.error, "Failed to register with the provider: %@", registerError.localizedDescription)
            self.currentConnection?.invalidate()
            self.currentConnection = nil
            completionHandler(false)
        }) as? ProviderCommunication else {
            fatalError("Failed to create a remote object proxy for the provider")
        }

        os_log("\(self.t)providerProxy.register 🛫")
        providerProxy.register(completionHandler)
    }

    /**
        This method is called by the provider to cause the app (if it is registered) to display a prompt to the user asking
        for a decision about a connection.
    */
    func promptUser(flow: NEFilterFlow, responseHandler:@escaping (Bool) -> Void) -> Bool {
        guard let connection = currentConnection else {
            os_log("Cannot prompt user because the app isn't registered")
            return false
        }

        guard let appProxy = connection.remoteObjectProxyWithErrorHandler({ promptError in
            os_log("Failed to prompt the user: %@", promptError.localizedDescription)
            self.currentConnection = nil
            responseHandler(true)
        }) as? AppCommunication else {
            fatalError("Failed to create a remote object proxy for the app")
        }

        appProxy.promptUser(flow: flow, responseHandler: responseHandler)

        return true
    }
    
    func providerSay(_ words: String) {
        os_log("IPC.providerSay")
        guard let connection = currentConnection else {
            os_log("Cannot prompt user because the app isn't registered")
            return
        }
        
        guard let appProxy = connection.remoteObjectProxyWithErrorHandler({ promptError in
            os_log("Failed to prompt the user: %@", promptError.localizedDescription)
        }) as? AppCommunication else {
            fatalError("Failed to create a remote object proxy for the app")
        }
        appProxy.providerSaid(words)
        os_log("Provider Said: \(words)")
    }
}

extension IPCConnection: NSXPCListenerDelegate {

    // MARK: NSXPCListenerDelegate

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        providerSay("IPCConnection.shouldAcceptNewConnection")
        // The exported object is this IPCConnection instance.
        newConnection.exportedInterface = NSXPCInterface(with: ProviderCommunication.self)
        newConnection.exportedObject = self

        // The remote object is the delegate of the app's IPCConnection instance.
        newConnection.remoteObjectInterface = NSXPCInterface(with: AppCommunication.self)

        newConnection.invalidationHandler = {
            self.currentConnection = nil
        }

        newConnection.interruptionHandler = {
            self.currentConnection = nil
        }

        currentConnection = newConnection
        newConnection.resume()

        return true
    }
}

extension IPCConnection: ProviderCommunication {
    // MARK: ProviderCommunication

    func register(_ completionHandler: @escaping (Bool) -> Void) {
        os_log("IPC.App registered")
        completionHandler(true)
    }
}
