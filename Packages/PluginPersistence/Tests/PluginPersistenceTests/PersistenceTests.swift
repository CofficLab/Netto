import Foundation
import KernelCore
import ProviderPersistence
import SwiftData
import XCTest
@testable import PluginPersistence

/// 持久化 schema 测试：模型属性与旧版一致、内存容器可用、服务注册。
@MainActor
final class PersistenceTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        try PersistenceService.inMemoryContainer()
    }

    func testSchemaStoresAppSetting() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let setting = AppSetting(appId: "com.example", allowed: false)
        context.insert(setting)
        try context.save()

        let fetch = FetchDescriptor<AppSetting>()
        let all = try context.fetch(fetch)
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.appId, "com.example")
        XCTAssertEqual(all.first?.allowed, false)
    }

    func testSchemaStoresFirewallEventWithLegacyRawValues() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let event = FirewallEventModel(
            id: "e1",
            time: Date(timeIntervalSince1970: 1_700_000_000),
            address: "example.com",
            port: "443",
            sourceAppIdentifier: "com.example",
            statusRawValue: 1,
            directionRawValue: 2
        )
        context.insert(event)
        try context.save()

        let fetch = FetchDescriptor<FirewallEventModel>()
        let all = try context.fetch(fetch)
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, "e1")
        XCTAssertEqual(all.first?.statusRawValue, 1)   // rejected
        XCTAssertEqual(all.first?.directionRawValue, 2) // outbound
        XCTAssertEqual(all.first?.isAllowed, false)
    }

    func testMultipleSettingsCoexist() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(AppSetting(appId: "a", allowed: true))
        context.insert(AppSetting(appId: "b", allowed: false))
        try context.save()

        let fetch = FetchDescriptor<AppSetting>()
        let all = try context.fetch(fetch)
        XCTAssertEqual(Set(all.map(\.appId)), ["a", "b"])
    }

    func testPersistencePluginRegistersService() throws {
        let kernel = KernelCoreContainer()
        let plugin = PersistencePlugin()
        try kernel.start(plugins: [plugin])
        XCTAssertNotNil(kernel.resolveProvider(PersistenceProviding.self))
        // PersistenceProviding 的 container 与生产 schema 一致。
        let service = kernel.resolveProvider(PersistenceProviding.self)
        XCTAssertNotNil(service?.container)
        try kernel.stop()
        XCTAssertNil(kernel.resolveProvider(PersistenceProviding.self))
    }
}
