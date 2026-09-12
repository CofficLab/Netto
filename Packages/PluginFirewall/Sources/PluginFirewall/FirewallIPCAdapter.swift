import Foundation
import NettoIPCContracts

/// 将 XPC 注册回调、连接失效和超时收敛到一个只能完成一次的结果。
///
/// 线程/actor：`@MainActor`。XPC 回调线程不得直接调用本类方法或 resume
/// 主线程 continuation（Swift 6 隔离断言会崩溃），所有外部回调必须先
/// `Task { @MainActor in }` 跳转；超时任务从主线程创建，继承 MainActor
/// 隔离。状态单线程访问，不使用锁与 `@unchecked Sendable`。
@MainActor
final class IPCRegistrationCompletion {
    private let timeout: Duration
    private var continuation: CheckedContinuation<Bool, Never>?
    private var timeoutTask: Task<Void, Never>?
    private var didComplete = false
    private var resultBeforeInstall: Bool?

    init(timeout: Duration = .seconds(10)) {
        self.timeout = timeout
    }

    func install(_ continuation: CheckedContinuation<Bool, Never>) {
        if didComplete {
            let result = resultBeforeInstall ?? false
            resultBeforeInstall = nil
            continuation.resume(returning: result)
            return
        }
        self.continuation = continuation

        let timeoutTask = Task { [weak self, timeout] in
            do {
                try await Task.sleep(for: timeout)
            } catch {
                return
            }
            self?.finish(false)
        }

        if didComplete {
            timeoutTask.cancel()
        } else {
            self.timeoutTask = timeoutTask
        }
    }

    func finish(_ succeeded: Bool) {
        guard !didComplete else {
            return
        }
        didComplete = true
        let continuation = self.continuation
        self.continuation = nil
        if continuation == nil {
            resultBeforeInstall = succeeded
        }
        let timerTask = self.timeoutTask
        self.timeoutTask = nil

        timerTask?.cancel()
        continuation?.resume(returning: succeeded)
    }
}

/// 在非隔离上下文创建 NSXPC 回调，避免 Swift 把闭包隐式绑定到调用方的
/// MainActor；回调线程必须经 `Task { @MainActor in }` 跳回主线程再解析
/// 完成门闩（直接调用会在 Swift 6 隔离断言下崩溃）。
private func makeIPCInvalidationHandler(
    _ registration: IPCRegistrationCompletion
) -> @Sendable () -> Void {
    { Task { @MainActor in registration.finish(false) } }
}

private func makeIPCErrorHandler(
    _ registration: IPCRegistrationCompletion
) -> (Error) -> Void {
    { _ in Task { @MainActor in registration.finish(false) } }
}

private func makeIPCRegisterReplyHandler(
    _ registration: IPCRegistrationCompletion
) -> (Bool) -> Void {
    { succeeded in Task { @MainActor in registration.finish(succeeded) } }
}

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

        let registration = IPCRegistrationCompletion()
        // XPC 回调只解析线程安全的结果门闩；连接清理由下方 await 返回后在
        // MainActor 上执行，避免让系统回调闭包继承错误的 actor 隔离。
        newConnection.invalidationHandler = makeIPCInvalidationHandler(registration)

        guard let providerProxy = newConnection.remoteObjectProxyWithErrorHandler(
            makeIPCErrorHandler(registration)
        ) as? ProviderCommunication else {
            newConnection.invalidate()
            if connection === newConnection { connection = nil }
            return false
        }

        let succeeded = await withCheckedContinuation { continuation in
            registration.install(continuation)
            providerProxy.register(makeIPCRegisterReplyHandler(registration))
        }

        if !succeeded {
            newConnection.invalidate()
            if connection === newConnection { connection = nil }
        }
        return succeeded
    }

    func unregister() {
        connection?.invalidate()
        connection = nil
    }
}
