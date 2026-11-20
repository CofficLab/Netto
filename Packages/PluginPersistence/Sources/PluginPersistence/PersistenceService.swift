import Foundation
import KernelCore
import ProviderPersistence
import ProviderStorage
import SwiftData

/// 事件插件独占的持久化服务。
///
/// 由 `PersistencePlugin` 创建并注册；容器指向 `<plugin dir>/events.sqlite`。
@MainActor
public final class EventStorePersistenceService: EventStorePersistenceProviding {
    public let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }
}

/// 设置插件独占的持久化服务。
///
/// 由 `PersistencePlugin` 创建并注册；容器指向 `<plugin dir>/settings.sqlite`。
@MainActor
public final class AppSettingsPersistenceService: AppSettingsPersistenceProviding {
    public let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }
}

/// 两个数据插件各自 ModelContainer 的唯一创建入口。
///
/// schema 与旧版完全一致（实体名 / 属性名 / raw 值语义不变），
/// 因此旧库数据可以逐条迁移到新库后直接读取。
@MainActor
public enum PersistenceContainers {
    static var eventStoreSchema: Schema {
        Schema([FirewallEventModel.self])
    }

    static var appSettingsSchema: Schema {
        Schema([AppSetting.self])
    }

    /// 旧版单库 schema（两个实体同库）。
    static var legacySchema: Schema {
        Schema([AppSetting.self, FirewallEventModel.self])
    }

    // MARK: - 生产容器

    static func eventStore(at url: URL) throws -> ModelContainer {
        try container(schema: eventStoreSchema, url: url, allowsSave: true)
    }

    static func appSettings(at url: URL) throws -> ModelContainer {
        try container(schema: appSettingsSchema, url: url, allowsSave: true)
    }

    /// 旧库容器；迁移只读，默认禁止写入。
    static func legacyStore(at url: URL, allowsSave: Bool = false) throws -> ModelContainer {
        try container(schema: legacySchema, url: url, allowsSave: allowsSave)
    }

    // MARK: - 测试容器

    public static func inMemoryEventStore() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: eventStoreSchema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: eventStoreSchema, configurations: [configuration])
    }

    public static func inMemoryAppSettings() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: appSettingsSchema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: appSettingsSchema, configurations: [configuration])
    }

    // MARK: - Helpers

    private static func container(
        schema: Schema,
        url: URL,
        allowsSave: Bool
    ) throws -> ModelContainer {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let configuration = ModelConfiguration(
            schema: schema,
            url: url,
            allowsSave: allowsSave,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

/// 持久化插件 —— 唯一负责创建生产 ModelContainer 的插件。
///
/// 每个数据插件拥有独立目录与独立 SQLite 文件：
/// - `StorageProviding.pluginDataDirectory(for: "eventstore")/events.sqlite`
/// - `StorageProviding.pluginDataDirectory(for: "appsettings")/settings.sqlite`
///
/// 生命周期：
/// - onBoot：解析 `StorageProviding`，创建两个容器并注册各自契约；
///   首次启动时把 v3 之前的单库数据复制迁移到新库。
/// - 无外部资源，onShutdown 只需注销（Kernel 自动撤回贡献）。
@MainActor
public final class PersistencePlugin: SuperPlugin {
    public let id = "persistence"
    public var order: Int { 1 }
    public var dependencies: [String] { [] }
    public let metadata = PluginMetadata(
        id: "persistence",
        name: "Persistence",
        description: "各数据插件独立 ModelContainer / SQLite 文件的唯一创建者",
        version: "2.0",
        policy: .required
    )

    private enum Mode {
        /// 生产：从 `StorageProviding` 解析目录并创建库。
        case production(legacyDatabaseURL: URL?)
        /// 测试：直接注入内存容器，不触碰磁盘。
        case injected(eventStore: ModelContainer, appSettings: ModelContainer)
    }

    private let mode: Mode

    public init() {
        self.mode = .production(legacyDatabaseURL: nil)
    }

    /// 覆盖旧库位置（迁移测试用）。
    public init(legacyDatabaseURL: URL) {
        self.mode = .production(legacyDatabaseURL: legacyDatabaseURL)
    }

    /// 注入容器（单元测试用）。
    public init(eventStoreContainer: ModelContainer, appSettingsContainer: ModelContainer) {
        self.mode = .injected(eventStore: eventStoreContainer, appSettings: appSettingsContainer)
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        switch mode {
        case .injected(let eventStore, let appSettings):
            try register(kernel: kernel, eventStore: eventStore, appSettings: appSettings)

        case .production(let legacyDatabaseURL):
            guard let storage = kernel.resolveProvider((any StorageProviding).self) else {
                throw PersistenceBootError.storageProviderMissing
            }

            let eventStoreURL = storage
                .pluginDataDirectory(for: PersistenceConfig.eventsPluginID)
                .appendingPathComponent(PersistenceConfig.eventsFileName)
            let appSettingsURL = storage
                .pluginDataDirectory(for: PersistenceConfig.settingsPluginID)
                .appendingPathComponent(PersistenceConfig.settingsFileName)

            let eventStore = try makeContainer(at: eventStoreURL) {
                try PersistenceContainers.eventStore(at: eventStoreURL)
            }
            let appSettings = try makeContainer(at: appSettingsURL) {
                try PersistenceContainers.appSettings(at: appSettingsURL)
            }

            LegacyDatabaseMigrator.migrateIfNeeded(
                legacyDatabaseURL: legacyDatabaseURL ?? PersistenceConfig.legacyDatabaseURL,
                dataRootDirectory: storage.dataRootDirectory,
                eventStoreContainer: eventStore,
                appSettingsContainer: appSettings
            )

            try register(kernel: kernel, eventStore: eventStore, appSettings: appSettings)
        }
    }

    private func register(
        kernel: KernelCoreContainer,
        eventStore: ModelContainer,
        appSettings: ModelContainer
    ) throws {
        try kernel.registerProvider(
            EventStorePersistenceProviding.self,
            EventStorePersistenceService(container: eventStore)
        )
        try kernel.registerProvider(
            AppSettingsPersistenceProviding.self,
            AppSettingsPersistenceService(container: appSettings)
        )
    }

    private func makeContainer(at url: URL, _ make: () throws -> ModelContainer) throws -> ModelContainer {
        do {
            return try make()
        } catch {
            throw PersistenceBootError.containerCreationFailed(url: url, underlying: error)
        }
    }
}

public enum PersistenceBootError: LocalizedError {
    case storageProviderMissing
    case containerCreationFailed(url: URL, underlying: any Error)

    public var errorDescription: String? {
        switch self {
        case .storageProviderMissing:
            return "缺少 StorageProviding：无法确定插件数据目录"
        case .containerCreationFailed(let url, let underlying):
            return "无法创建数据库 \(url.path)：\(underlying.localizedDescription)"
        }
    }
}
