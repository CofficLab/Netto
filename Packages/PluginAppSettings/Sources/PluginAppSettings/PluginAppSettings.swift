import Foundation
import KernelCore
import ProviderPersistence
import ProviderAppSettings

/// 应用设置插件。
///
/// 生命周期：
/// - onBoot：解析 `AppSettingsPersistenceProviding`（设置插件独占容器），
///   创建 `AppSettingsStore` 并注册 `AppSettingsProviding`；
///   缺失持久化服务即抛错回滚（硬依赖）。
/// - onReadyAsync：把全部规则载入内存。内核按 order 顺序执行 onReady，
///   order 10 早于防火墙插件的 30，因此 IPC 开始接受连接前缓存必定就绪。
/// - onShutdown：Kernel 自动撤回贡献（Provider 随 owner 注销）。
@MainActor
public final class PluginAppSettings: AsyncSuperPlugin {
    public let id = PersistenceConfig.settingsPluginID
    public var order: Int { 10 }
    public var dependencies: [String] { ["persistence"] }
    public let metadata = PluginMetadata(
        id: PersistenceConfig.settingsPluginID,
        name: "AppSettings",
        description: "应用允许/阻止规则存储（SwiftData）",
        version: "1.0",
        policy: .required
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        let persistence = try kernel.requireProvider(AppSettingsPersistenceProviding.self)
        let store = AppSettingsStore(container: persistence.container)
        try kernel.registerProvider(AppSettingsProviding.self, store)
    }

    public func onReadyAsync(kernel: KernelCoreContainer) async throws {
        guard let store = kernel.resolveProvider(AppSettingsProviding.self) as? AppSettingsStore else {
            throw KernelCoreError.providerNotFound(type: AppSettingsProviding.self)
        }
        try await store.prepare()
    }
}