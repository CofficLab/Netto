import Foundation
import NettoIPCContracts

/// IPC 适配器契约 —— App 侧与 Extension 的 NSXPC 关联面。
///
/// 生产实现 `NSXPCFirewallIPCAdapter` 迁移自旧 `Bridge/IPCConnection` 的
/// App 客户端角色；测试注入 Mock，验证 register/unregister 生命周期。
@MainActor
protocol FirewallIPCServing: AnyObject {
    /// 与 Extension 建立关联（Mach service NSXPC register）。
    /// - Returns: 是否关联成功（失败时内部已清理连接）。
    func register() async -> Bool

    /// 断开关联并清理连接（onShutdown 调用）。
    func unregister()

    /// 导出的 AppCommunication 对象（NSXPC 远端回调 App 侧决策）。
    var exportedAppCommunication: (any AppCommunication)? { get set }
}

/// 生产 IPC 适配器：App 客户端角色（迁移自旧 `IPCConnection` 的
/// `register(withExtension:delegate:)` / `extensionMachServiceName(from:)`）。
///
/// 线程/actor：`@MainActor`；`register()` 以 continuation 包装旧 completion 回调。
@MainActor
final class NSXPCFirewallIPCAdapter: FirewallIPCServing {
    private let extensionBundle: Bundle
    private var connection: NSXPCConnection?
    weak var exportedAppCommunication: (any AppCommunication)?

    init(extensionBundle: Bundle) {
        self.extensionBundle = extensionBundle
    }

    // MARK: - 提取 Mach service 名（旧 extensionMachServiceName）

    private func extensionMachServiceName(from bundle: Bundle) -> String {
        guard let networkExtensionKeys = bundle.object(forInfoDictionaryKey: "NetworkExtension") as? [String: Any],
              let machServiceName = networkExtensionKeys["NEMachServiceName"] as? String else {
            fatalError("Mach service name is missing from the Info.plist")
        }
        return machServiceName
    }

    // MARK: - 关联（旧 register(withExtension:delegate:completionHandler:)）

    func register() async -> Bool {
        unregister()

        guard let delegate = exportedAppCommunication else {
            return false
        }

        let machServiceName = extensionMachServiceName(from: extensionBundle)
        let newConnection = NSXPCConnection(machServiceName: machServiceName, options: [])

        // 导出的对象是 AppCommunication（插件实现的 promptUser 决策入口）。
        newConnection.exportedInterface = NSXPCInterface(with: AppCommunication.self)
        newConnection.exportedObject = delegate

        // 远端对象是 Extension 的 ProviderCommunication。
        newConnection.remoteObjectInterface = NSXPCInterface(with: ProviderCommunication.self)

        connection = newConnection
        newConnection.resume()

        guard let providerProxy = newConnection.remoteObjectProxyWithErrorHandler({ [weak self] _ in
            Task { @MainActor [weak self] in
                self?.connection?.invalidate()
                self?.connection = nil
            }
        }) as? ProviderCommunication else {
            connection?.invalidate()
            connection = nil
            return false
        }

        let succeeded = await withCheckedContinuation { continuation in
            providerProxy.register { success in
                continuation.resume(returning: success)
            }
        }

        if !succeeded {
            connection?.invalidate()
            connection = nil
        }
        return succeeded
    }

    func unregister() {
        connection?.invalidate()
        connection = nil
    }
}
