/*
Abstract:
This file contains the implementation of the app <-> provider IPC connection
*/

import Foundation
import OSLog
import Network
import NetworkExtension

/// The IPCConnection class is used by both the app and the system extension to communicate with each other
class IPCConnection: NSObject {
    private static let logPrefix = "🤝 IPCConnection | "
    var listener: NSXPCListener?
    var currentConnection: NSXPCConnection?
    weak var delegate: AppCommunication?
    
    nonisolated(unsafe) static let shared = IPCConnection()
    
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
        os_log("\(Self.logPrefix)🚀 Starting XPC listener for mach service \(machServiceName)")

        let newListener = NSXPCListener(machServiceName: machServiceName)
        newListener.delegate = self
        newListener.resume()
        listener = newListener
    }

    /// This method is called by the app to register with the provider running in the system extension.
    func register(withExtension bundle: Bundle, delegate: AppCommunication, completionHandler: @escaping (Bool) -> Void) {
        self.delegate = delegate

        guard currentConnection == nil else {
            os_log("\(Self.logPrefix)⚠️ IPC.register: Already registered with the provider")
            completionHandler(true)
            return
        }
        
        os_log("\(Self.logPrefix)🛫 IPC.register")

        let machServiceName = extensionMachServiceName(from: bundle)
        let newConnection = NSXPCConnection(machServiceName: machServiceName, options: [])

        // The exported object is the delegate.
        newConnection.exportedInterface = NSXPCInterface(with: AppCommunication.self)
        newConnection.exportedObject = delegate

        // The remote object is the provider's IPCConnection instance.
        newConnection.remoteObjectInterface = NSXPCInterface(with: ProviderCommunication.self)

        currentConnection = newConnection
        newConnection.resume()

        guard let providerProxy = newConnection.remoteObjectProxyWithErrorHandler({ [weak self, weak newConnection] registerError in
            os_log(.error, "\(Self.logPrefix)Failed to register with the provider: \(registerError)")
            // 只有当前连接仍是这个连接时才清理，避免旧连接的迟到错误清掉新连接。
            if let self, self.currentConnection === newConnection {
                self.currentConnection?.invalidate()
                self.currentConnection = nil
            }
            completionHandler(false)
        }) as? ProviderCommunication else {
            fatalError("Failed to create a remote object proxy for the provider")
        }

        os_log("\(Self.logPrefix)🛫 providerProxy.register")
        providerProxy.register(completionHandler)
    }

    /**
        This method is called by the provider to cause the app (if it is registered) to display a prompt to the user asking
        for a decision about a connection.
    */
    func promptUser(flow: NEFilterFlow, responseHandler:@escaping (Bool) -> Void) -> Bool {
        os_log("\(Self.logPrefix)🍋 promptUser")
        
        guard let connection = currentConnection else {
            os_log("Cannot prompt user because the app isn't registered")
            return false
        }

        guard let appProxy = connection.remoteObjectProxyWithErrorHandler({ [weak self] promptError in
            os_log("Failed to prompt the user: %@", promptError.localizedDescription)
            // 失败时放行（fail-open）；只清理出错的那个连接。
            if self?.currentConnection === connection {
                self?.currentConnection = nil
            }
            responseHandler(true)
        }) as? AppCommunication else {
            fatalError("Failed to create a remote object proxy for the app")
        }

        appProxy.promptUser(id: flow.getAppId(), hostname:flow.getHostname(), port: flow.getRemotePort(), direction: flow.direction, responseHandler: responseHandler)

        return true
    }
    
    func log(_ message: String) {
        os_log("🧩 IPC.providerSay")
        guard let connection = currentConnection else {
            os_log("🧩 Cannot prompt user because the app isn't registered")
            return
        }
        
        guard let appProxy = connection.remoteObjectProxyWithErrorHandler({ promptError in
            os_log("🧩 Failed to prompt the user: %@", promptError.localizedDescription)
        }) as? AppCommunication else {
            fatalError("🧩 Failed to create a remote object proxy for the app")
        }
        appProxy.extensionLog(message)
    }
}

extension IPCConnection: NSXPCListenerDelegate {

    // MARK: NSXPCListenerDelegate

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        log("IPCConnection.shouldAcceptNewConnection")
        // The exported object is this IPCConnection instance.
        newConnection.exportedInterface = NSXPCInterface(with: ProviderCommunication.self)
        newConnection.exportedObject = self

        // The remote object is the delegate of the app's IPCConnection instance.
        newConnection.remoteObjectInterface = NSXPCInterface(with: AppCommunication.self)

        // 失效/中断可能晚于新连接到达（App 重注册时），只在当前连接仍是
        // 被失效的那个对象时清理，否则会把新连接一并丢掉并静默放行。
        newConnection.invalidationHandler = { [weak self, weak newConnection] in
            guard let self, let newConnection, self.currentConnection === newConnection else { return }
            self.currentConnection = nil
        }

        newConnection.interruptionHandler = { [weak self, weak newConnection] in
            guard let self, let newConnection, self.currentConnection === newConnection else { return }
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
