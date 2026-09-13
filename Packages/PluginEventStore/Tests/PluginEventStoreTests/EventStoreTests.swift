import Foundation
import KernelCore
import NetworkExtension
import PluginPersistence
import ProviderFirewallEvents
import ProviderPersistence
import SwiftData
import XCTest
@testable import PluginEventStore

/// 事件存储测试：分页/筛选/统计/删除/维护/变更流/方向映射/插件生命周期。
@MainActor
final class EventStoreTests: XCTestCase {

    private func makeStore() throws -> EventStore {
        let container = try PersistenceService.inMemoryContainer()
        return EventStore(container: container)
    }

    private func makeEvent(
        id: String,
        appId: String,
        address: String = "example.com",
        port: String = "443",
        status: FirewallEventDecision = .allowed,
        direction: FirewallTrafficDirection = .outbound,
        time: Date = Date()
    ) -> FirewallEventSnapshot {
        FirewallEventSnapshot(
            id: id,
            time: time,
            address: address,
            port: port,
            sourceAppIdentifier: appId,
            status: status,
            direction: direction,
            appId: appId
        )
    }

    // MARK: - 分页

    func testPaginationOffsetAndTotal() async throws {
        let store = try makeStore()
        for i in 0..<25 {
            try await store.create(makeEvent(id: "e\(i)", appId: "com.a", time: Date().addingTimeInterval(Double(i))))
        }
        let page0 = try await store.fetchPage(FirewallEventQuery(page: 0, pageSize: 10))
        XCTAssertEqual(page0.totalCount, 25)
        XCTAssertEqual(page0.events.count, 10)
        XCTAssertTrue(page0.hasNextPage)

        let page2 = try await store.fetchPage(FirewallEventQuery(page: 2, pageSize: 10))
        XCTAssertEqual(page2.events.count, 5)
        XCTAssertFalse(page2.hasNextPage)
    }

    // MARK: - 时间范围

    /// 验证 fetchByTimeRange：边界包含、应用筛选、时间倒序（镜像旧 Repo 语义）。
    func testFetchByTimeRangeBoundsAppFilterAndOrder() async throws {
        let store = try makeStore()
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        // 4 条：范围内 2 条（时间升序写入），范围外 2 条
        try await store.create(makeEvent(id: "t0", appId: "com.a", time: base.addingTimeInterval(100)))
        try await store.create(makeEvent(id: "t1", appId: "com.b", time: base.addingTimeInterval(200)))
        try await store.create(makeEvent(id: "out0", appId: "com.a", time: base.addingTimeInterval(-50)))
        try await store.create(makeEvent(id: "out1", appId: "com.a", time: base.addingTimeInterval(500)))

        // 注意：create 不携带自定义 id（镜像旧 DTO 自动生成语义），按 appId 断言。
        let all = try await store.fetchByTimeRange(from: base, to: base.addingTimeInterval(300), appIdentifier: nil)
        XCTAssertEqual(Set(all.map(\.appId)), Set(["com.a", "com.b"]))
        // 倒序：com.b（time 200）在前
        XCTAssertEqual(all.first?.appId, "com.b")

        let onlyA = try await store.fetchByTimeRange(from: base, to: base.addingTimeInterval(300), appIdentifier: "com.a")
        XCTAssertEqual(onlyA.map(\.appId), ["com.a"])

        // 边界含端点
        let endpoint = try await store.fetchByTimeRange(from: base, to: base.addingTimeInterval(100), appIdentifier: nil)
        XCTAssertEqual(endpoint.map(\.appId), ["com.a"])
        XCTAssertEqual(endpoint.first?.time, base.addingTimeInterval(100))
    }

    // MARK: - 筛选

    func testFilterByStatusDirectionAndApp() async throws {
        let store = try makeStore()
        try await store.create(makeEvent(id: "a1", appId: "com.a", status: .allowed, direction: .inbound))
        try await store.create(makeEvent(id: "a2", appId: "com.a", status: .rejected, direction: .outbound))
        try await store.create(makeEvent(id: "b1", appId: "com.b", status: .rejected, direction: .inbound))

        let rejectedA = try await store.fetchPage(
            FirewallEventQuery(appIdentifier: "com.a", status: .rejected)
        )
        XCTAssertEqual(rejectedA.events.count, 1)
        XCTAssertEqual(rejectedA.events.first?.appId, "com.a")
        XCTAssertEqual(rejectedA.events.first?.status, .rejected)

        let inboundAll = try await store.fetchPage(
            FirewallEventQuery(direction: .inbound)
        )
        XCTAssertEqual(Set(inboundAll.events.map(\.appId)), ["com.a", "com.b"])

        let count = try await store.count(
            FirewallEventCountQuery(appIdentifier: "com.a", status: .rejected, direction: .outbound)
        )
        XCTAssertEqual(count, 1)
    }

    // MARK: - 统计

    func testCountsAndAppIds() async throws {
        let store = try makeStore()
        try await store.create(makeEvent(id: "1", appId: "com.a", status: .allowed))
        try await store.create(makeEvent(id: "2", appId: "com.b", status: .rejected))
        try await store.create(makeEvent(id: "3", appId: "com.b", status: .rejected))

        let total = try await store.totalCount()
        XCTAssertEqual(total, 3)
        let appIds = try await store.allAppIds()
        XCTAssertEqual(appIds, ["com.a", "com.b"])

        let since = Date().addingTimeInterval(-1)
        let recent = try await store.appIdsSince(since)
        XCTAssertEqual(recent, ["com.a", "com.b"])
        let old = try await store.appIdsSince(Date().addingTimeInterval(3600))
        XCTAssertEqual(old, [])
    }

    // MARK: - 删除 / 清理

    func testDeleteByAppAndAll() async throws {
        let store = try makeStore()
        try await store.create(makeEvent(id: "1", appId: "com.a"))
        try await store.create(makeEvent(id: "2", appId: "com.b"))
        try await store.deleteByAppId("com.a")
        let result = try await store.totalCount()
        XCTAssertEqual(result, 1)
        let deleted = try await store.deleteAll()
        XCTAssertEqual(deleted, 1)
        let finalCount = try await store.totalCount()
        XCTAssertEqual(finalCount, 0)
    }

    func testCleanupOlderThan() async throws {
        let store = try makeStore()
        let old = Date().addingTimeInterval(-40 * 24 * 3600)
        let recent = Date()
        try await store.create(makeEvent(id: "old", appId: "com.a", time: old))
        try await store.create(makeEvent(id: "new", appId: "com.b", time: recent))
        let removed = try await store.cleanupOlderThan(days: 30)
        XCTAssertEqual(removed, 1)
        let result = try await store.totalCount()
        XCTAssertEqual(result, 1)
    }

    // MARK: - 维护

    func testTriggerMaintenanceRemovesExpiredAndReportsHealth() async throws {
        let store = try makeStore()
        try await store.create(makeEvent(id: "old", appId: "com.a", time: Date().addingTimeInterval(-40 * 24 * 3600)))
        let result = try await store.triggerMaintenance()
        XCTAssertTrue(result.isSuccessful)
        XCTAssertEqual(result.deletedEventCount, 1)
        let remaining = try await store.totalCount()
        XCTAssertEqual(remaining, 0)
    }

    // MARK: - 变更流

    func testChangeStreamEmitsCreatedAndCleared() async throws {
        let store = try makeStore()
        let task = Task {
            var changes: [FirewallEventChange] = []
            for await change in store.observeChanges() {
                changes.append(change)
                if changes.count == 2 { return changes }
            }
            return changes
        }
        try? await Task.sleep(for: .milliseconds(100))
        try await store.create(makeEvent(id: "x", appId: "com.a"))
        _ = try await store.deleteAll()
        let received = await task.value
        XCTAssertEqual(received.count, 2)
        guard case .created(let snapshot) = received[0] else {
            return XCTFail("期望 created 事件")
        }
        XCTAssertEqual(snapshot.id, "x")
        XCTAssertEqual(received[1], .cleared)
    }

    // MARK: - 方向/状态存储映射（与 NETrafficDirection 对齐）

    func testDirectionRawValuesMatchNETrafficDirection() {
        XCTAssertEqual(FirewallTrafficDirection.inbound.storageRawValue, NETrafficDirection.inbound.rawValue)
        XCTAssertEqual(FirewallTrafficDirection.outbound.storageRawValue, NETrafficDirection.outbound.rawValue)
    }

    // MARK: - 插件生命周期

    func testPluginRegistersAndMaintains() async throws {
        let kernel = KernelCoreContainer()
        try await kernel.startAsync(plugins: [PersistencePlugin(), PluginAppSettingsPluginForTest(), PluginEventStore()])
        XCTAssertNotNil(kernel.resolveProvider(FirewallEventsProviding.self))
        let store = kernel.resolveProvider(FirewallEventsProviding.self) as? EventStore
        XCTAssertNotNil(store)
        try await kernel.stopAsync()
        XCTAssertNil(kernel.resolveProvider(FirewallEventsProviding.self))
    }

    // MARK: - 旧 schema 只读回归

    func testLegacySchemaShapeRoundTrip() async throws {
        // 用与旧 App 完全相同的属性形状（实体名 + 属性名 + raw 值语义）写入，
        // 再用插件容器读回：验证旧 db.sqlite 的数据可直接被新 schema 读取。
        let schema = Schema([
            AppSetting.self,
            FirewallEventModel.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        context.insert(
            FirewallEventModel(
                id: "legacy-1",
                time: Date(timeIntervalSince1970: 1_700_000_000),
                address: "legacy.example",
                port: "80",
                sourceAppIdentifier: "com.legacy",
                statusRawValue: 1,
                directionRawValue: 2
            )
        )
        try context.save()

        let store = EventStore(container: container)
        let page = try await store.fetchPage(FirewallEventQuery(page: 0, pageSize: 10))
        XCTAssertEqual(page.totalCount, 1)
        XCTAssertEqual(page.events.first?.id, "legacy-1")
        XCTAssertEqual(page.events.first?.status, .rejected)
        XCTAssertEqual(page.events.first?.direction, .outbound)
        XCTAssertEqual(page.events.first?.appId, "com.legacy")
    }
}

/// 测试用最小 AppSettings 插件占位（仅用于组装 kernel 生命周期验证）。
@MainActor
private final class PluginAppSettingsPluginForTest: SuperPlugin {
    let id = "appsettings-test"
    var order: Int { 10 }
    var dependencies: [String] { ["persistence"] }
    let metadata = PluginMetadata(name: "AppSettings-Test", version: "1.0", policy: .required)

    func onBoot(kernel: KernelCoreContainer) throws {
        let persistence = try kernel.requireProvider(PersistenceProviding.self)
        _ = persistence.container
    }
}
