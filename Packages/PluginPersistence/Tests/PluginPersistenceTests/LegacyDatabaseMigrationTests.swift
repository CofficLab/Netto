import Foundation
import KernelCore
import ProviderPersistence
import ProviderStorage
import SwiftData
import XCTest
@testable import PluginPersistence

/// 旧版单库 -> 各插件独立库的一次性复制迁移。
@MainActor
final class LegacyDatabaseMigrationTests: XCTestCase {

    private func makeTempRoot() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("NetpauseMigrationTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func writeLegacyDatabase(
        at url: URL,
        settings: [(appId: String, allowed: Bool)],
        events: [FirewallEventModel]
    ) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let container = try PersistenceContainers.legacyStore(at: url, allowsSave: true)
        let context = ModelContext(container)
        for setting in settings {
            context.insert(AppSetting(appId: setting.appId, allowed: setting.allowed))
        }
        for event in events {
            context.insert(event)
        }
        try context.save()
    }

    private func startKernel(storageRoot: URL, legacyURL: URL) throws -> KernelCoreContainer {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider(
            (any StorageProviding).self,
            DefaultStorageProvider(dataRootDirectory: storageRoot)
        )
        try kernel.start(plugins: [PersistencePlugin(legacyDatabaseURL: legacyURL)])
        return kernel
    }

    private func makeEvent(id: String) -> FirewallEventModel {
        FirewallEventModel(
            id: id,
            time: Date(timeIntervalSince1970: 1_700_000_000),
            address: "example.com",
            port: "443",
            sourceAppIdentifier: "com.example",
            statusRawValue: 1,
            directionRawValue: 2
        )
    }

    func testLegacyDatabaseIsCopiedIntoPerPluginStores() throws {
        let root = makeTempRoot()
        let storageRoot = root.appendingPathComponent("data", isDirectory: true)
        let legacyURL = root.appendingPathComponent("legacy/db.sqlite")

        try writeLegacyDatabase(
            at: legacyURL,
            settings: [("com.allowed", true), ("com.denied", false)],
            events: [makeEvent(id: "e1"), makeEvent(id: "e2")]
        )

        let kernel = try startKernel(storageRoot: storageRoot, legacyURL: legacyURL)
        defer { try? kernel.stop() }

        let eventsContainer = try XCTUnwrap(kernel.resolveProvider(EventStorePersistenceProviding.self)?.container)
        let settingsContainer = try XCTUnwrap(kernel.resolveProvider(AppSettingsPersistenceProviding.self)?.container)

        let events = try ModelContext(eventsContainer).fetch(FetchDescriptor<FirewallEventModel>())
        XCTAssertEqual(Set(events.map(\.id)), ["e1", "e2"])

        let settings = try ModelContext(settingsContainer).fetch(FetchDescriptor<AppSetting>())
        XCTAssertEqual(Set(settings.map(\.appId)), ["com.allowed", "com.denied"])

        XCTAssertTrue(FileManager.default.fileExists(atPath: legacyURL.path), "旧库应保留（复制而非移动）")
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: storageRoot.appendingPathComponent(LegacyDatabaseMigrator.markerFileName).path
            ),
            "迁移成功后应写入标记文件"
        )
    }

    func testMigrationRunsOnlyOnce() throws {
        let root = makeTempRoot()
        let storageRoot = root.appendingPathComponent("data", isDirectory: true)
        let legacyURL = root.appendingPathComponent("legacy/db.sqlite")

        try writeLegacyDatabase(at: legacyURL, settings: [], events: [makeEvent(id: "e1")])

        let firstKernel = try startKernel(storageRoot: storageRoot, legacyURL: legacyURL)
        try firstKernel.stop()

        // 首次迁移后旧库又多了数据：标记文件存在时不应再次复制。
        let legacy = try PersistenceContainers.legacyStore(at: legacyURL, allowsSave: true)
        let legacyContext = ModelContext(legacy)
        legacyContext.insert(makeEvent(id: "e2"))
        try legacyContext.save()

        let secondKernel = try startKernel(storageRoot: storageRoot, legacyURL: legacyURL)
        defer { try? secondKernel.stop() }

        let eventsContainer = try XCTUnwrap(secondKernel.resolveProvider(EventStorePersistenceProviding.self)?.container)
        let events = try ModelContext(eventsContainer).fetch(FetchDescriptor<FirewallEventModel>())
        XCTAssertEqual(events.map(\.id), ["e1"], "已迁移过就不应再次复制")
    }
}
