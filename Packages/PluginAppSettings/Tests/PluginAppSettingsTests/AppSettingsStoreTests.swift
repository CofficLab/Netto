import Foundation
import KernelCore
import PluginPersistence
import ProviderAppSettings
import SwiftData
import XCTest
@testable import PluginAppSettings

/// AppSettings 存储测试：CRUD、决策、计数、变更流、插件装配与缺依赖失败。
@MainActor
final class AppSettingsStoreTests: XCTestCase {

    private func makeStore() async throws -> (AppSettingsStore, ModelContainer) {
        let container = try PersistenceContainers.inMemoryAppSettings()
        let store = AppSettingsStore(container: container)
        try await store.prepare()
        return (store, container)
    }

    func testUpsertCreatesAndUpdates() async throws {
        let (store, _) = try await makeStore()
        try await store.setDeny("com.example")
        var snapshot = try await store.find("com.example")
        XCTAssertEqual(snapshot?.allowed, false)

        try await store.setAllow("com.example")
        snapshot = try await store.find("com.example")
        XCTAssertEqual(snapshot?.allowed, true)
    }

    func testShouldAllowDefaultsToTrueWhenNoRule() async throws {
        let (store, _) = try await makeStore()
        let allowed = await store.shouldAllow("unknown.app")
        XCTAssertTrue(allowed)
        XCTAssertTrue(store.shouldAllowSync("unknown.app"))
    }

    func testShouldAllowRespectsRule() async throws {
        let (store, _) = try await makeStore()
        try await store.setDeny("blocked.app")
        let allowed = await store.shouldAllow("blocked.app")
        XCTAssertFalse(allowed)
        XCTAssertFalse(store.shouldAllowSync("blocked.app"))
    }

    func testDeniedAppsAndCount() async throws {
        let (store, _) = try await makeStore()
        try await store.setDeny("a")
        try await store.setAllow("b")
        try await store.setDeny("c")

        let denied = try await store.deniedApps()
        XCTAssertEqual(Set(denied.map(\.appId)), ["a", "c"])
        let deniedCount = try await store.deniedAppsCount()
        XCTAssertEqual(deniedCount, 2)
        let all = try await store.fetchAll()
        XCTAssertEqual(Set(all.map(\.appId)), ["a", "b", "c"])
    }

    func testDeleteRemovesRule() async throws {
        let (store, _) = try await makeStore()
        try await store.setDeny("x")
        try await store.delete("x")
        let removed = try await store.find("x")
        XCTAssertNil(removed)
        let allowed = await store.shouldAllow("x")
        XCTAssertTrue(allowed)
    }

    func testPrepareHydratesRulesFromDisk() async throws {
        let container = try PersistenceContainers.inMemoryAppSettings()
        let writer = AppSettingsStore(container: container)
        try await writer.prepare()
        try await writer.setDeny("blocked.app")

        // 新实例模拟应用重启：prepare() 之后决策必须立刻命中规则。
        let reader = AppSettingsStore(container: container)
        try await reader.prepare()
        XCTAssertFalse(reader.shouldAllowSync("blocked.app"))
        XCTAssertTrue(reader.shouldAllowSync("unknown.app"))
    }

    func testChangeStreamEmitsAllowDeny() async throws {
        let (store, _) = try await makeStore()
        let task = Task {
            var changes: [AppSettingsChange] = []
            for await change in store.observeChanges() {
                changes.append(change)
                if changes.count == 2 { return changes }
            }
            return changes
        }
        try? await Task.sleep(for: .milliseconds(100))
        try await store.setDeny("a")
        try await store.setAllow("a")
        let received = await task.value
        XCTAssertEqual(received, [.didDeny(appId: "a"), .didAllow(appId: "a")])
    }

    func testMultipleObserversAllReceiveChanges() async throws {
        let (store, _) = try await makeStore()
        let first = Task { await self.firstChange(in: store.observeChanges()) }
        let second = Task { await self.firstChange(in: store.observeChanges()) }
        try? await Task.sleep(for: .milliseconds(100))
        try await store.setDeny("a")
        let firstChange = await first.value
        let secondChange = await second.value
        // 多个订阅者必须同时收到变更：新订阅不能顶掉旧订阅。
        XCTAssertEqual(firstChange, .didDeny(appId: "a"))
        XCTAssertEqual(secondChange, .didDeny(appId: "a"))
    }

    /// 等待变更流的首个事件（超时返回 nil，避免用例挂死）。
    private func firstChange(
        in stream: AsyncStream<AppSettingsChange>,
        timeout: Duration = .seconds(3)
    ) async -> AppSettingsChange? {
        await withTaskGroup(of: AppSettingsChange?.self) { group in
            group.addTask {
                for await change in stream {
                    return change
                }
                return nil
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }
            let result = await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }

    func testPluginRegistersProvider() async throws {
        let kernel = KernelCoreContainer()
        // 注入内存容器：生产模式会从 StorageProviding 解析插件目录并写盘。
        let persistence = PersistencePlugin(
            eventStoreContainer: try PersistenceContainers.inMemoryEventStore(),
            appSettingsContainer: try PersistenceContainers.inMemoryAppSettings()
        )
        try await kernel.startAsync(plugins: [persistence, PluginAppSettings()])
        XCTAssertNotNil(kernel.resolveProvider(AppSettingsProviding.self))
        let store = kernel.resolveProvider(AppSettingsProviding.self)
        XCTAssertNotNil(store)
        try await kernel.stopAsync()
        XCTAssertNil(kernel.resolveProvider(AppSettingsProviding.self))
    }

    func testPluginFailsWithoutPersistence() {
        let kernel = KernelCoreContainer()
        XCTAssertThrowsError(try kernel.start(plugins: [PluginAppSettings()])) { error in
            // 缺失硬依赖 → 明确错误，不做强制解包。
            XCTAssertNotNil(error)
        }
        // 依赖校验失败发生在状态机进入 starting 之前，内核保持 stopped。
        XCTAssertEqual(kernel.lifecycleState, .stopped)
        XCTAssertEqual(kernel.registeredPluginCount, 0)
    }
}
