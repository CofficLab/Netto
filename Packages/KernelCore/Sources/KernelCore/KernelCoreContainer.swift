import Foundation

/// Kernel 生命周期状态机。
public enum KernelLifecycleState: Sendable, Equatable {
    case stopped
    case starting
    case running
    case stopping
    case failed
}

/// 插件启用状态的持久化抽象。
///
/// 由宿主注入（例如基于 UserDefaults 的实现）；KernelCore 不绑定具体存储。
public protocol PluginEnableStateStoring: Sendable {
    /// 读取某插件已持久化的启用覆盖值；无覆盖返回 nil。
    func enabledState(pluginID: String) -> Bool?

    /// 持久化某插件的启用覆盖值。
    func setEnabled(_ enabled: Bool, pluginID: String)
}

/// KernelCore 容器 —— Netto 每个 App 进程唯一运行内核。
///
/// 职责：
/// 1. Provider 按协议类型注册、解析、注销，并记录 owner 插件。
/// 2. 插件按稳定 ID 注册、依赖排序、生命周期启动/停止。
/// 3. 记录插件拥有的贡献 Token，并在停止/禁用/失败时逆序撤回。
/// 4. 校验重复 ID、缺失依赖、依赖环和非法生命周期操作。
/// 5. 支持同步与异步插件；异步阶段支持取消与超时，不遗留后台任务。
///
/// 不负责：SwiftUI/AppKit 视图、NEFilterManager、StoreKit、SwiftData、
/// 具体 Repo/Service/Plugin、把全部状态通过一个 ObservableObject 广播。
///
/// 线程/actor：容器本身是 `@MainActor`；Provider 值要求 `Sendable`。
@MainActor
public final class KernelCoreContainer {
    /// 异步生命周期阶段的超时（可在启动前配置）。
    public var asyncPhaseTimeout: Duration = .seconds(30)

    /// 当前生命周期状态。
    public internal(set) var lifecycleState: KernelLifecycleState = .stopped

    /// 插件启用状态持久化（可选；nil 时只使用策略默认值）。
    public var enableStateStore: (any PluginEnableStateStoring)?

    /// 旧插件 ID → 新插件 ID 的别名映射（迁移期兼容，可选）。
    public var legacyPluginIDAliases: [String: String] = [:]

    // MARK: - Provider 注册表

    /// 协议类型 → Provider 实例。键为 `ObjectIdentifier(协议元类型)`。
    private var providers: [ObjectIdentifier: any Sendable] = [:]

    /// 协议类型 → owner 插件 ID（用于停止/禁用时按 owner 撤回）。
    private var providerOwners: [ObjectIdentifier: String] = [:]

    // MARK: - 插件注册表

    /// 插件 ID → 插件实例（跨文件扩展访问，模块内可见）。
    var plugins: [String: any SuperPlugin] = [:]

    /// 插件 ID → 有效启用状态（策略 + 用户覆盖）。
    var pluginEnabledStates: [String: Bool] = [:]

    /// 实际启动顺序（诊断与逆序停止的依据）。
    var pluginStartOrder: [String] = []

    // MARK: - 贡献登记

    /// owner 插件 ID → 贡献 Token 列表（按登记顺序；撤回时逆序）。
    private var contributionsByOwner: [String: [ContributionToken]] = [:]

    /// 创建内核容器。
    public init() {}
}

// MARK: - Provider 注册 / 解析 / 注销

extension KernelCoreContainer {
    /// 按协议类型注册 Provider。
    ///
    /// - Parameters:
    ///   - provider: Provider 实例（必须 `Sendable`）。
    ///   - type: 协议元类型，默认推断。
    ///   - owner: 拥有该 Provider 的插件 ID（便于停止时撤回）。
    /// - Throws: `providerAlreadyRegistered` 同类型重复注册时。
    public func registerProvider<P>(_ provider: P, for type: P.Type = P.self, owner: String? = nil) throws where P: Sendable {
        let key = ObjectIdentifier(type)
        guard providers[key] == nil else {
            throw KernelCoreError.providerAlreadyRegistered(type: String(describing: type))
        }
        providers[key] = provider
        if let owner {
            providerOwners[key] = owner
        }
    }

    /// 解析 Provider；缺失时返回 nil（**明确 unavailable**，不做强制解包）。
    public func resolveProvider<P>(_ type: P.Type) -> P? where P: Sendable {
        providers[ObjectIdentifier(type)] as? P
    }

    /// 解析必需 Provider；缺失时抛出 `providerNotFound`。
    ///
    /// 供需要在缺失时立即失败并回滚的插件生命周期使用。
    public func requireProvider<P>(_ type: P.Type) throws -> P where P: Sendable {
        guard let provider = resolveProvider(type) else {
            throw KernelCoreError.providerNotFound(type: String(describing: type))
        }
        return provider
    }

    /// 当前已注册 Provider 数量（诊断/测试用）。
    public var registeredProviderCount: Int { providers.count }

    /// 注销某个插件拥有的全部 Provider。
    /// - Parameter owner: owner 插件 ID。
    func removeProviders(ownedByPlugin owner: String) {
        let keys = providerOwners.compactMap { key, ownerID in ownerID == owner ? key : nil }
        for key in keys {
            providers.removeValue(forKey: key)
            providerOwners.removeValue(forKey: key)
        }
    }
}

// MARK: - 贡献登记 / 撤回

extension KernelCoreContainer {
    /// 登记插件拥有的贡献 Token。
    ///
    /// - Returns: Token ID（诊断用）。
    /// - Note: 同一 owner 的 Token 在 `cancelContributions(ownedBy:)` 时按
    ///   登记顺序逆序撤回。
    @discardableResult
    public func registerContribution(_ token: ContributionToken, owner: String) -> String {
        contributionsByOwner[owner, default: []].append(token)
        return token.id
    }

    /// 撤回某个 owner 插件的全部贡献（逆序），并清空登记。
    public func cancelContributions(ownedBy owner: String) {
        let tokens = contributionsByOwner.removeValue(forKey: owner) ?? []
        for token in tokens.reversed() {
            token.revoke()
        }
    }

    /// 某个 owner 插件当前登记的贡献数量（诊断/测试用）。
    public func contributionCount(ownedBy owner: String) -> Int {
        contributionsByOwner[owner]?.count ?? 0
    }
}
