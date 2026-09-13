import Foundation
import KernelCore
import ProviderPersistence
import ProviderAppSettings

/// 应用设置插件。
///
/// 生命周期：
/// - onBoot：解析 `PersistenceProviding`，创建 `AppSettingsStore` 并注册
///   `AppSettingsProviding`；缺失持久化服务即抛错回滚（硬依赖）。
/// - onShutdown：Kernel 自动撤回贡献（Provider 随 owner 注销）。
@MainActor
public final class PluginAppSettings: SuperPlugin {
    public let id = "appsettings"
    public var order: Int { 10 }
    public var dependencies: [String] { ["persistence"] }
    public let metadata = PluginMetadata(
        name: "AppSettings",
        version: "1.0",
        policy: .required,
        summary: "应用允许/阻止规则存储（SwiftData）"
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        let persistence = try kernel.requireProvider(PersistenceProviding.self)
        let store = AppSettingsStore(container: persistence.container)
        try kernel.registerProvider(store, for: AppSettingsProviding.self, owner: id)
    }
}
