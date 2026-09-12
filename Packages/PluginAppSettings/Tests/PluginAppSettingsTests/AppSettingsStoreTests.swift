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

    private func makeStore() throws -> (AppSettingsStore, ModelContainer) {
        let container = try PersistenceService.inMemoryContainer()
        return (AppSettingsStore(container: container), container)
    }

    func testUpsertCreatesAndUpdates() async throws {
        let (store, _) = try makeStore()
        try await store.setDeny("com.example")
        var snapshot = try await store.find("com.example")
        XCTAssertEqual(snapshot?.allowed, false)

        try await store.setAllow("com.example")
        snapshot = try await store.find("com.example")
        XCTAssertEqual(snapshot?.allowed, true)
    }

    func testShouldAllowDefaultsToTrueWhenNoRule() async throws {
        let (store, _) = try makeStore()
        let allowed = await store.shouldAllow("unknown.app")
        XCTAssertTrue(allowed)
        XCTAssertTrue(store.shouldAllowSync("unknown.app"))
    }

    func testShouldAllowRespectsRule() async throws {
        let (store, _) = try makeStore()
        try await store.setDeny("blocked.app")
        let allowed = await store.shouldAllow("blocked.app")
        XCTAssertFalse(allowed)
        XCTAssertFalse(store.shouldAllowSync("blocked.app"))
    }

    func testDeniedAppsAndCount() async throws {
        let (store, _) = try makeStore()
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
        let (store, _) = try makeStore()
        try await store.setDeny("x")
        try await store.delete("x")
        let removed = try await store.find("x")
        XCTAssertNil(removed)
        let allowed = await store.shouldAllow("x")
        XCTAssertTrue(allowed)
    }

    func testChangeStreamEmitsAllowDeny() async throws {
        let (store, _) = try makeStore()
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

    func testPluginRegistersProvider() throws {
        let kernel = KernelCoreContainer()
        try kernel.start(plugins: [PersistencePlugin(), PluginAppSettings()])
        XCTAssertNotNil(kernel.resolveProvider(AppSettingsProviding.self))
        let store = kernel.resolveProvider(AppSettingsProviding.self)
        XCTAssertNotNil(store)
        try kernel.stop()
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
