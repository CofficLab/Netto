import Foundation
import KernelCore
import SwiftData

/// 持久化能力（插件内部基础设施，不面向视图）。
///
/// 由 `PersistencePlugin` 创建并注册；EventStore / AppSettings 插件通过它
/// 获取**同一个** ModelContainer，保证同一 db.sqlite 只有一个容器实例。
@MainActor
public protocol PersistenceProviding: AnyObject, Sendable {
    /// 共享 ModelContainer。
    var container: ModelContainer { get }
}

/// 持久化服务 —— 持有 ModelContainer。
@MainActor
public final class PersistenceService: PersistenceProviding {
    public let container: ModelContainer

    /// 使用指定容器初始化（测试注入用）。
    public init(container: ModelContainer) {
        self.container = container
    }

    /// 使用生产配置创建容器（旧 `container()` 语义：失败即终止启动）。
    public convenience init(production: Void) {
        let schema = Schema([
            AppSetting.self,
            FirewallEventModel.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: PersistenceConfig.databaseURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            self.init(container: container)
        } catch {
            fatalError("无法创建 primaryContainer: \n\(error)")
        }
    }

    /// 内存容器（测试用；schema 与生产完全一致）。
    public static func inMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            AppSetting.self,
            FirewallEventModel.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
}

/// 持久化插件 —— 唯一负责创建生产 ModelContainer 的插件。
///
/// 生命周期：
/// - onBoot：创建容器并注册 `PersistenceProviding`。
/// - 无外部资源，onShutdown 只需注销（Kernel 自动撤回贡献）。
@MainActor
public final class PersistencePlugin: SuperPlugin {
    public let id = "persistence"
    public var order: Int { 1 }
    public var dependencies: [String] { [] }
    public let metadata = PluginMetadata(
        name: "Persistence",
        version: "1.0",
        policy: .required,
        summary: "SwiftData ModelContainer / db.sqlite 单一所有者"
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        let service = PersistenceService(production: ())
        try kernel.registerProvider(service, for: PersistenceProviding.self, owner: id)
    }
}
