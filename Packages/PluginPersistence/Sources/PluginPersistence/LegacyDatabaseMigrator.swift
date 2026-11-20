import Foundation
import os
import ProviderPersistence
import SwiftData

/// 把 v3 之前的单库 `~/Documents/debug|production/db.sqlite`
/// 一次性复制到各插件的独立库；旧文件保留不删除（与 Lumi 迁移规则一致）。
///
/// 迁移仅在「标记文件不存在且旧库存在」时执行；成功后写入标记文件，
/// 失败不写标记，下次启动重试。重试前会清空目标容器，避免半迁移留下重复行。
@MainActor
enum LegacyDatabaseMigrator {
    nonisolated static let markerFileName = ".netto-storage-migration.json"
    private static let logger = Logger(subsystem: "com.yueyi.TravelMode", category: "persistence")

    static func migrateIfNeeded(
        legacyDatabaseURL: URL,
        dataRootDirectory: URL,
        eventStoreContainer: ModelContainer,
        appSettingsContainer: ModelContainer
    ) {
        let fileManager = FileManager.default
        let markerURL = dataRootDirectory.appendingPathComponent(markerFileName)

        guard !fileManager.fileExists(atPath: markerURL.path) else { return }
        guard fileManager.fileExists(atPath: legacyDatabaseURL.path) else { return }

        do {
            let legacy = try PersistenceContainers.legacyStore(at: legacyDatabaseURL)
            let legacyContext = ModelContext(legacy)

            let settingCount = try copySettings(from: legacyContext, into: appSettingsContainer)
            let eventCount = try copyEvents(from: legacyContext, into: eventStoreContainer)

            let marker = MigrationMarker(
                migratedAt: .now,
                legacyDatabasePath: legacyDatabaseURL.path,
                settingCount: settingCount,
                eventCount: eventCount
            )
            let data = try JSONEncoder().encode(marker)
            try data.write(to: markerURL, options: [.atomic])
            logger.info("旧数据库迁移完成：\(settingCount) 条规则，\(eventCount) 条事件")
        } catch {
            logger.error("旧数据库迁移失败，保留旧库并将在下次启动重试：\(error.localizedDescription)")
        }
    }

    // MARK: - Copy

    private static func copySettings(
        from legacyContext: ModelContext,
        into container: ModelContainer
    ) throws -> Int {
        let legacySettings = try legacyContext.fetch(FetchDescriptor<AppSetting>())
        let context = ModelContext(container)
        try context.delete(model: AppSetting.self)
        for setting in legacySettings {
            context.insert(AppSetting(appId: setting.appId, allowed: setting.allowed))
        }
        try context.save()
        return legacySettings.count
    }

    private static func copyEvents(
        from legacyContext: ModelContext,
        into container: ModelContainer
    ) throws -> Int {
        let context = ModelContext(container)
        try context.delete(model: FirewallEventModel.self)
        try context.save()

        let pageSize = 500
        var offset = 0
        var copied = 0
        while true {
            var descriptor = FetchDescriptor<FirewallEventModel>(
                sortBy: [SortDescriptor(\FirewallEventModel.time, order: .forward)]
            )
            descriptor.fetchOffset = offset
            descriptor.fetchLimit = pageSize
            let page = try legacyContext.fetch(descriptor)
            guard !page.isEmpty else { break }

            for event in page {
                context.insert(FirewallEventModel(
                    id: event.id,
                    time: event.time,
                    address: event.address,
                    port: event.port,
                    sourceAppIdentifier: event.sourceAppIdentifier,
                    statusRawValue: event.statusRawValue,
                    directionRawValue: event.directionRawValue
                ))
            }
            try context.save()

            copied += page.count
            offset += page.count
            if page.count < pageSize { break }
        }
        return copied
    }
}

private struct MigrationMarker: Codable {
    let migratedAt: Date
    let legacyDatabasePath: String
    let settingCount: Int
    let eventCount: Int
}
