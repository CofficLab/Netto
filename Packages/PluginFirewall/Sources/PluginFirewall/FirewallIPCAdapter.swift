import Foundation
import NettoIPCContracts
import OSLog

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

/// 跟踪当前 IPC 连接令牌，判定一次连接断开是否属于「注册成功后的意外断开」。
///
/// 只有当前已注册成功的连接被外部失效/中断时才算意外断开；主动
/// `unregister()`、重新注册时被替换掉的旧连接都不算。
@MainActor
final class IPCConnectionRegistry {
    private var activeToken: UUID?
    private var registeredToken: UUID?

    /// 开始一次新的注册尝试；此前注册的连接立即失效（视为被替换）。
    func beginRegistration() -> UUID {
        let token = UUID()
        activeToken = token
        registeredToken = nil
        return token
    }

    /// 注册成功：标记该连接为「已注册」。
    func markRegistered(_ token: UUID) {
        guard activeToken == token else { return }
        registeredToken = token
    }

    /// 主动断开或注册失败：清除该连接的全部登记。
    func cancel(_ token: UUID) {
        if activeToken == token { activeToken = nil }
        if registeredToken == token { registeredToken = nil }
    }

    /// 清除全部登记（主动断开）。
    func clearAll() {
        activeToken = nil
        registeredToken = nil
    }

    /// 消费一次连接断开事件；返回 true 表示这是注册成功后的意外断开。
    func consumeUnexpectedLoss(_ token: UUID) -> Bool {
        guard registeredToken == token else { return false }
        registeredToken = nil
        if activeToken == token { activeToken = nil }
        return true
    }
}

private let ipcLogger = Logger(subsystem: "com.yueyi.TravelMode.PluginFirewall", category: "ipc")

/// 在非隔离上下文创建 NSXPC 回调，避免 Swift 把闭包隐式绑定到调用方的
/// MainActor；回调线程必须经 `Task { @MainActor in }` 跳回主线程再解析
/// 完成门闩（直接调用会在 Swift 6 隔离断言下崩溃）。
private func makeIPCErrorHandler(
    _ registration: IPCRegistrationCompletion
) -> (Error) -> Void {
    { error in
        ipcLogger.error("IPC register: 连接错误 \(error.localizedDescription, privacy: .public)")
        Task { @MainActor in registration.finish(false) }
    }
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

    /// 注册成功后的意外断开回调（连接失效/中断）。
    ///
    /// 主动 `unregister()` 与注册失败不会触发。用于触发上层重新关联 IPC。
    var connectionLossHandler: (@MainActor () -> Void)? { get set }
}

/// 生产 IPC 适配器：App 客户端角色（迁移自旧 `IPCConnection` 的
/// `register(withExtension:delegate:)` / `extensionMachServiceName(from:)`）。
///
/// 线程/actor：`@MainActor`；`register()` 以 continuation 包装旧 completion 回调。
@MainActor
final class NSXPCFirewallIPCAdapter: FirewallIPCServing {
    /// 系统扩展 Bundle；nil 表示宿主环境无扩展（非 App 宿主降级运行）。
    private let extensionBundle: Bundle?
    private var connection: NSXPCConnection?
    private let registry = IPCConnectionRegistry()
    private let logger = Logger(subsystem: "com.yueyi.TravelMode.PluginFirewall", category: "ipc")
    weak var exportedAppCommunication: (any AppCommunication)?
    var connectionLossHandler: (@MainActor () -> Void)?

    init(extensionBundle: Bundle?) {
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
            logger.error("IPC register: exportedAppCommunication 为空")
            return false
        }

        // 扩展 Bundle 缺失（非 App 宿主降级）：无法定位 Mach service，直接失败。
        guard let extensionBundle else {
            logger.error("IPC register: 系统扩展 Bundle 缺失")
            return false
        }

        let machServiceName = extensionMachServiceName(from: extensionBundle)
        let newConnection = NSXPCConnection(machServiceName: machServiceName, options: [])

        // 导出的对象是 AppCommunication（插件实现的 promptUser 决策入口）。
        newConnection.exportedInterface = NSXPCInterface(with: AppCommunication.self)
        newConnection.exportedObject = delegate

        // 远端对象是 Extension 的 ProviderCommunication。
        newConnection.remoteObjectInterface = NSXPCInterface(with: ProviderCommunication.self)

        let token = registry.beginRegistration()
        connection = newConnection
        newConnection.resume()

        let registration = IPCRegistrationCompletion()
        // XPC 回调只解析线程安全的结果门闩；连接清理由下方 await 返回后在
        // MainActor 上执行，避免让系统回调闭包继承错误的 actor 隔离。
        // 失效/中断回调同时承担「注册成功后意外断开」的上报职责。
        let lossAwareHandler = makeConnectionTerminationHandler(registration: registration, token: token)
        newConnection.invalidationHandler = lossAwareHandler
        newConnection.interruptionHandler = lossAwareHandler

        guard let providerProxy = newConnection.remoteObjectProxyWithErrorHandler(
            makeIPCErrorHandler(registration)
        ) as? ProviderCommunication else {
            logger.error("IPC register: 无法创建 ProviderCommunication 代理")
            registry.cancel(token)
            newConnection.invalidate()
            if connection === newConnection { connection = nil }
            return false
        }

        let succeeded = await withCheckedContinuation { continuation in
            registration.install(continuation)
            providerProxy.register(makeIPCRegisterReplyHandler(registration))
        }

        if !succeeded {
            registry.cancel(token)
            newConnection.invalidate()
            if connection === newConnection { connection = nil }
            return false
        }

        registry.markRegistered(token)
        return true
    }

    func unregister() {
        registry.clearAll()
        connection?.invalidate()
        connection = nil
    }

    /// 连接失效/中断：注册前让门闩失败，注册后上报意外断开。
    private func makeConnectionTerminationHandler(
        registration: IPCRegistrationCompletion,
        token: UUID
    ) -> @Sendable () -> Void {
        { [weak self] in
            Task { @MainActor in
                registration.finish(false)
                self?.handleConnectionTermination(token: token)
            }
        }
    }

    /// 注册成功后的意外断开：清理连接并通知上层重新关联。
    private func handleConnectionTermination(token: UUID) {
        guard registry.consumeUnexpectedLoss(token) else { return }
        connection = nil
        logger.error("IPC 连接在注册成功后断开，需要重新关联")
        connectionLossHandler?()
    }
}
