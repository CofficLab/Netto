import Foundation
import KernelCore
import ProviderPersistence
import ProviderFirewallEvents

/// 事件存储插件。
///
/// 生命周期：
/// - onBoot：解析 `PersistenceProviding`，创建 `EventStore` 并注册
///   `FirewallEventsProviding`（缺失持久化服务即抛错回滚）。
/// - onReadyAsync：启动定期维护（初始清理 + 每小时任务）。
/// - onShutdownAsync：停止维护并取消在途任务（不遗留后台任务）。
@MainActor
public final class PluginEventStore: AsyncSuperPlugin {
    public let id = "eventstore"
    public var order: Int { 10 }
    public var dependencies: [String] { ["persistence"] }
    public let metadata = PluginMetadata(
        id: "eventstore",
        name: "EventStore",
        description: "防火墙事件存储（SwiftData + 定期维护）",
        version: "1.0",
        policy: .required
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        let persistence = try kernel.requireProvider(PersistenceProviding.self)
        let store = EventStore(container: persistence.container)
        try kernel.registerProvider(FirewallEventsProviding.self, store)
    }

    public func onReadyAsync(kernel: KernelCoreContainer) async throws {
        guard let store = kernel.resolveProvider(FirewallEventsProviding.self) as? EventStore else {
            throw KernelCoreError.providerNotFound(type: FirewallEventsProviding.self)
        }
        store.startMaintenance()
    }

    public func onShutdownAsync(kernel: KernelCoreContainer) async throws {
        guard let store = kernel.resolveProvider(FirewallEventsProviding.self) as? EventStore else {
            return
        }
        store.stopMaintenance()
    }
}
