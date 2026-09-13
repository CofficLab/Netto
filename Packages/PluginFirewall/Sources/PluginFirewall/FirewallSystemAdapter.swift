import Foundation
import NetworkExtension
import SystemExtensions

/// 系统扩展安装属性（值类型；从 `OSSystemExtensionProperties` 提取，测试可注入）。
struct SystemExtensionPropertyInfo: Sendable, Equatable {
    let bundleIdentifier: String
    let bundleVersion: String
    let bundleShortVersion: String
    let urlPath: String
    let isEnabled: Bool
    let isAwaitingUserApproval: Bool
    let isUninstalling: Bool

    init(
        bundleIdentifier: String,
        bundleVersion: String,
        bundleShortVersion: String,
        urlPath: String,
        isEnabled: Bool,
        isAwaitingUserApproval: Bool,
        isUninstalling: Bool
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.bundleVersion = bundleVersion
        self.bundleShortVersion = bundleShortVersion
        self.urlPath = urlPath
        self.isEnabled = isEnabled
        self.isAwaitingUserApproval = isAwaitingUserApproval
        self.isUninstalling = isUninstalling
    }
}

/// 系统扩展请求类型。
enum SystemExtensionRequestKind: Sendable {
    /// 激活请求（可能触发用户审批弹窗）。
    case activate
    /// 属性查询请求。
    case properties
}

/// 系统扩展请求结果回调（生产桥接在系统回调线程跳转 MainActor 后分发）。
@MainActor
protocol SystemExtensionRequestHandling: AnyObject {
    /// 激活请求完成（成功）。
    func systemExtensionActivationCompleted()
    /// 需要用户同意激活系统扩展。
    func systemExtensionNeedsUserApproval()
    /// 请求失败。
    func systemExtensionRequestFailed(_ error: Error)
    /// 收到已安装属性列表。
    func systemExtensionProperties(_ properties: [SystemExtensionPropertyInfo])
}

/// 系统交互适配器契约 —— PluginFirewall 对 NEFilterManager /
/// OSSystemExtensionManager / OSSystemExtensionsWorkspace 的唯一访问面。
///
/// 生产实现 `SystemFirewallAdapter` 封装真实系统调用（迁移自旧
/// FirewallService+Filter / +SystemExt）；测试注入 Mock，保证状态机与
/// 生命周期可在无 entitlement 环境确定性验证。
@MainActor
protocol FirewallSystemAdapting: AnyObject {
    /// App 是否安装在 /Applications 目录。
    var isAppInApplicationsFolder: Bool { get }

    /// 当前 App 捆绑的系统扩展版本信息（nil 表示扩展 bundle 缺失）。
    var currentExtensionVersion: (version: String, shortVersion: String, identifier: String)? { get }

    /// 加载过滤器偏好并返回是否启用（旧 `isFilterEnabled`/`loadFromPreferences` 语义）。
    func loadFilterEnabled() async throws -> Bool

    /// 安装过滤器配置到系统设置（旧 `installFilter` 的配置段）。
    /// 约定：调用前已确认过滤器未启用。
    func installFilterConfiguration() async throws

    /// 启用过滤器（isEnabled=true + saveToPreferences）。
    func enableFilter() async throws

    /// 停止过滤器（isEnabled=false + saveToPreferences）。
    func disableFilter() async throws

    /// 注册过滤器配置变更观察者；回调在主线程执行，返回 token。
    func addFilterConfigurationObserver(_ handler: @escaping @MainActor @Sendable (Bool) -> Void) -> Any

    /// 移除过滤器配置变更观察者。
    func removeFilterConfigurationObserver(_ token: Any)

    /// 提交系统扩展请求（激活/属性），结果经 `SystemExtensionRequestHandling` 回调。
    func submitSystemExtensionRequest(_ kind: SystemExtensionRequestKind)

    /// 注册 OSSystemExtensionsWorkspace 观察者（macOS 15.1+；失败静默）。
    func registerWorkspaceObserver(handler: @escaping @MainActor @Sendable () -> Void)

    /// 注销 OSSystemExtensionsWorkspace 观察者。
    func unregisterWorkspaceObserver()

    /// 设置系统扩展请求结果接收者（生产适配器注入；Mock 可忽略）。
    func setRequestHandler(_ handler: (any SystemExtensionRequestHandling)?)
}

extension FirewallSystemAdapting {
    func setRequestHandler(_ handler: (any SystemExtensionRequestHandling)?) {}
}

/// 生产系统适配器：封装 NEFilterManager / OSSystemExtensionManager /
/// OSSystemExtensionsWorkspace 的真实调用（迁移自旧 FirewallService）。
///
/// 线程/actor：`@MainActor`；ObjC 系统回调经独立桥接类跳回主线程后转发，
/// 不使用 `@unchecked Sendable`。
@MainActor
final class SystemFirewallAdapter: FirewallSystemAdapting {
    private let extensionBundle: Bundle
    private let requestBridge: SystemExtensionRequestBridge
    private let requestBox = WeakRequestHandlerBox()
    private var filterObserver: Any?
    private var workspaceObserver: AnyObject?
    private(set) var workspaceObserverRegistered = false

    /// - Parameters:
    ///   - extensionBundle: 系统扩展 Bundle（定位扩展标识）。
    ///   - requestHandler: 系统扩展请求结果接收者（通常为 FirewallController）。
    init(extensionBundle: Bundle, requestHandler: (any SystemExtensionRequestHandling)? = nil) {
        self.extensionBundle = extensionBundle
        self.requestBox.handler = requestHandler
        self.requestBridge = SystemExtensionRequestBridge(box: requestBox)
    }

    /// 更新请求结果接收者（插件装配时注入）。
    func setRequestHandler(_ handler: (any SystemExtensionRequestHandling)?) {
        requestBox.handler = handler
    }

    // MARK: - 应用目录检查（旧 isAppInApplicationsFolder）

    var isAppInApplicationsFolder: Bool {
        let appPath = Bundle.main.bundlePath
        return appPath.hasPrefix("/Applications")
    }

    // MARK: - 扩展版本信息（旧 getCurrentExtensionVersion）

    var currentExtensionVersion: (version: String, shortVersion: String, identifier: String)? {
        guard let identifier = extensionBundle.bundleIdentifier else { return nil }
        guard let version = extensionBundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String else { return nil }
        guard let shortVersion = extensionBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return nil }
        return (version: version, shortVersion: shortVersion, identifier: identifier)
    }

    // MARK: - 过滤器操作（迁移自 FirewallService+Filter）

    func loadFilterEnabled() async throws -> Bool {
        let manager = NEFilterManager.shared()
        try await manager.loadFromPreferences()
        return manager.isEnabled
    }

    func installFilterConfiguration() async throws {
        let manager = NEFilterManager.shared()
        try await manager.loadFromPreferences()

        if manager.providerConfiguration == nil {
            let providerConfiguration = NEFilterProviderConfiguration()
            providerConfiguration.filterSockets = true
            providerConfiguration.filterPackets = false
            manager.providerConfiguration = providerConfiguration
            if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
                manager.localizedDescription = appName
            }
        }

        // 先以未启用状态保存，触发系统授权弹窗。
        manager.isEnabled = false
        try await manager.saveToPreferences()
    }

    func enableFilter() async throws {
        let manager = NEFilterManager.shared()
        try await manager.loadFromPreferences()
        manager.isEnabled = true
        try await manager.saveToPreferences()
    }

    func disableFilter() async throws {
        let manager = NEFilterManager.shared()
        manager.isEnabled = false
        try await manager.saveToPreferences()
    }

    // MARK: - 过滤器配置变更观察（旧 setObserver）

    func addFilterConfigurationObserver(_ handler: @escaping @MainActor @Sendable (Bool) -> Void) -> Any {
        let token = NotificationCenter.default.addObserver(
            forName: .NEFilterConfigurationDidChange,
            object: nil,
            queue: .main
        ) { _ in
            let enabled = NEFilterManager.shared().isEnabled
            Task { @MainActor in
                handler(enabled)
            }
        }
        filterObserver = token
        return token
    }

    func removeFilterConfigurationObserver(_ token: Any) {
        NotificationCenter.default.removeObserver(token)
        if let filterObserver, token as AnyObject === filterObserver as AnyObject {
            self.filterObserver = nil
        }
    }

    // MARK: - 系统扩展请求（迁移自 FirewallService+SystemExt）

    func submitSystemExtensionRequest(_ kind: SystemExtensionRequestKind) {
        guard let identifier = extensionBundle.bundleIdentifier else { return }

        let request: OSSystemExtensionRequest
        switch kind {
        case .activate:
            request = OSSystemExtensionRequest.activationRequest(
                forExtensionWithIdentifier: identifier,
                queue: .main
            )
        case .properties:
            request = OSSystemExtensionRequest.propertiesRequest(
                forExtensionWithIdentifier: identifier,
                queue: .main
            )
        }
        request.delegate = requestBridge
        OSSystemExtensionManager.shared.submitRequest(request)
    }

    // MARK: - OSSystemExtensionsWorkspaceObserver（迁移自 FirewallService+SystemExt）

    func registerWorkspaceObserver(handler: @escaping @MainActor @Sendable () -> Void) {
        guard #available(macOS 15.1, *), !workspaceObserverRegistered else { return }
        let bridge = WorkspaceObserverBridge(handler: handler)
        do {
            try OSSystemExtensionsWorkspace.shared.addObserver(bridge)
            workspaceObserver = bridge
            workspaceObserverRegistered = true
        } catch {
            workspaceObserver = nil
        }
    }

    func unregisterWorkspaceObserver() {
        guard #available(macOS 15.1, *), workspaceObserverRegistered else { return }
        if let observer = workspaceObserver as? (any OSSystemExtensionsWorkspaceObserver) {
            OSSystemExtensionsWorkspace.shared.removeObserver(observer)
        }
        workspaceObserver = nil
        workspaceObserverRegistered = false
    }
}

/// 请求接收者的弱引用盒：允许插件装配后再绑定控制器，闭包跨隔离捕获安全。
@MainActor
final class WeakRequestHandlerBox {
    weak var handler: (any SystemExtensionRequestHandling)?
}

/// OSSystemExtensionRequestDelegate 桥接：把系统回调跳回 MainActor。
///
/// 线程/actor：普通 NSObject（非隔离）；回调到达后经 `Task { @MainActor }`
/// 调用初始化时构造的 @Sendable 闭包。闭包以弱引用捕获接收者盒，
/// 不跨隔离发送 `self`。
final class SystemExtensionRequestBridge: NSObject, OSSystemExtensionRequestDelegate {
    private let onActivationCompleted: @MainActor @Sendable () -> Void
    private let onRequestFailed: @MainActor @Sendable (Error) -> Void
    private let onNeedsUserApproval: @MainActor @Sendable () -> Void
    private let onFoundProperties: @MainActor @Sendable ([SystemExtensionPropertyInfo]) -> Void

    init(box: WeakRequestHandlerBox) {
        self.onActivationCompleted = { [weak box] in
            box?.handler?.systemExtensionActivationCompleted()
        }
        self.onRequestFailed = { [weak box] error in
            box?.handler?.systemExtensionRequestFailed(error)
        }
        self.onNeedsUserApproval = { [weak box] in
            box?.handler?.systemExtensionNeedsUserApproval()
        }
        self.onFoundProperties = { [weak box] properties in
            box?.handler?.systemExtensionProperties(properties)
        }
    }

    func request(
        _ request: OSSystemExtensionRequest,
        didFinishWithResult result: OSSystemExtensionRequest.Result
    ) {
        switch result {
        case .completed:
            let action = onActivationCompleted
            Task { @MainActor in
                action()
            }
        case .willCompleteAfterReboot:
            break
        @unknown default:
            break
        }
    }

    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        let action = onRequestFailed
        Task { @MainActor in
            action(error)
        }
    }

    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        let action = onNeedsUserApproval
        Task { @MainActor in
            action()
        }
    }

    func request(
        _ request: OSSystemExtensionRequest,
        foundProperties properties: [OSSystemExtensionProperties]
    ) {
        let mapped = properties.map {
            SystemExtensionPropertyInfo(
                bundleIdentifier: $0.bundleIdentifier,
                bundleVersion: $0.bundleVersion,
                bundleShortVersion: $0.bundleShortVersion,
                urlPath: $0.url.path,
                isEnabled: $0.isEnabled,
                isAwaitingUserApproval: $0.isAwaitingUserApproval,
                isUninstalling: $0.isUninstalling
            )
        }
        let action = onFoundProperties
        Task { @MainActor in
            action(mapped)
        }
    }

    nonisolated func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension newExtension: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        .replace
    }
}

/// 将 `OSSystemExtensionsWorkspaceObserver` 回调桥接为闭包。
///
/// 线程/actor：普通 NSObject（非隔离）；回调到达后跳回 MainActor 再执行 handler。
@available(macOS 15.1, *)
final class WorkspaceObserverBridge: NSObject, OSSystemExtensionsWorkspaceObserver {
    private let handler: @MainActor @Sendable () -> Void

    init(handler: @escaping @MainActor @Sendable () -> Void) {
        self.handler = handler
    }

    func systemExtensionWillBecomeEnabled(_ systemExtensionInfo: OSSystemExtensionInfo) {
        let action = handler
        Task { @MainActor in
            action()
        }
    }

    func systemExtensionWillBecomeDisabled(_ systemExtensionInfo: OSSystemExtensionInfo) {}

    func systemExtensionWillBecomeInactive(_ systemExtensionInfo: OSSystemExtensionInfo) {}
}
