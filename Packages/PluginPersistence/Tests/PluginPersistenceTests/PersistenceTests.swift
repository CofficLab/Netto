import Foundation
import KernelCore
import ProviderPersistence
import ProviderStorage
import SwiftData
import XCTest
@testable import PluginPersistence

/// 持久化插件测试：独立容器注册、按插件目录建库、schema 往返。
@MainActor
final class PersistenceTests: XCTestCase {

    private func makeTempRoot() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("NetpausePersistenceTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testInjectedContainersRegisterSeparateProviders() throws {
        let kernel = KernelCoreContainer()
        let eventStoreContainer = try PersistenceContainers.inMemoryEventStore()
        let appSettingsContainer = try PersistenceContainers.inMemoryAppSettings()
        let plugin = PersistencePlugin(
            eventStoreContainer: eventStoreContainer,
            appSettingsContainer: appSettingsContainer
        )

        try kernel.start(plugins: [plugin])

        let eventService = kernel.resolveProvider(EventStorePersistenceProviding.self)
        let settingsService = kernel.resolveProvider(AppSettingsPersistenceProviding.self)
        XCTAssertTrue(eventService?.container === eventStoreContainer)
        XCTAssertTrue(settingsService?.container === appSettingsContainer)

        try kernel.stop()
        XCTAssertNil(kernel.resolveProvider(EventStorePersistenceProviding.self))
        XCTAssertNil(kernel.resolveProvider(AppSettingsPersistenceProviding.self))
    }

    func testProductionCreatesOneDatabasePerPluginDirectory() throws {
        let root = makeTempRoot()
        let kernel = KernelCoreContainer()
        try kernel.registerProvider(
            (any StorageProviding).self,
            DefaultStorageProvider(dataRootDirectory: root)
        )
        // 不存在的旧库路径：避免测试进程读取开发者真实 Documents 数据。
        let plugin = PersistencePlugin(
            legacyDatabaseURL: root.appendingPathComponent("missing-legacy.sqlite")
        )

        try kernel.start(plugins: [plugin])

        let fileManager = FileManager.default
        let eventsURL = root
            .appendingPathComponent(PersistenceConfig.eventsPluginID, isDirectory: true)
            .appendingPathComponent(PersistenceConfig.eventsFileName)
        let settingsURL = root
            .appendingPathComponent(PersistenceConfig.settingsPluginID, isDirectory: true)
            .appendingPathComponent(PersistenceConfig.settingsFileName)
        XCTAssertTrue(fileManager.fileExists(atPath: eventsURL.path))
        XCTAssertTrue(fileManager.fileExists(atPath: settingsURL.path))
        XCTAssertNotNil(kernel.resolveProvider(EventStorePersistenceProviding.self))
        XCTAssertNotNil(kernel.resolveProvider(AppSettingsPersistenceProviding.self))

        try kernel.stop()
    }

    func testProductionFailsWithoutStorageProvider() {
        let kernel = KernelCoreContainer()
        XCTAssertThrowsError(try kernel.start(plugins: [PersistencePlugin()]))
        XCTAssertEqual(kernel.lifecycleState, .failed)
    }

    func testSchemaStoresAppSettingInSettingsContainer() throws {
        let container = try PersistenceContainers.inMemoryAppSettings()
        let context = ModelContext(container)
        context.insert(AppSetting(appId: "com.example", allowed: false))
        try context.save()

        let all = try context.fetch(FetchDescriptor<AppSetting>())
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.appId, "com.example")
        XCTAssertEqual(all.first?.allowed, false)
    }

    func testSchemaStoresFirewallEventWithLegacyRawValues() throws {
        let container = try PersistenceContainers.inMemoryEventStore()
        let context = ModelContext(container)
        context.insert(FirewallEventModel(
            id: "e1",
            time: Date(timeIntervalSince1970: 1_700_000_000),
            address: "example.com",
            port: "443",
            sourceAppIdentifier: "com.example",
            statusRawValue: 1,
            directionRawValue: 2
        ))
        try context.save()

        let all = try context.fetch(FetchDescriptor<FirewallEventModel>())
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, "e1")
        XCTAssertEqual(all.first?.statusRawValue, 1)   // rejected
        XCTAssertEqual(all.first?.directionRawValue, 2) // outbound
        XCTAssertEqual(all.first?.isAllowed, false)
    }
}
