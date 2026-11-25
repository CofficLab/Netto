import Foundation
import ProviderAppSettings
import ProviderFirewallEvents
import Testing
@testable import PluginFirewallDashboard

/// 规则变更后应用列表必须重载（issue #10）。
@MainActor
@Suite("应用列表规则变更重载")
struct AppListModelReloadTests {

    @Test("禁止后应用立即从允许分桶移到禁止分桶")
    func reloadsAfterDeny() async throws {
        let settings = MockSettings()
        let events = MockEvents(appIdsSince: ["com.alpha"])
        let catalog = StubCatalog()
        let model = AppListModel()

        await model.load(catalog: catalog, settings: settings, events: events)
        #expect(model.filteredApps(for: .Allowed).map(\.id) == ["com.alpha"])
        #expect(model.filteredApps(for: .Rejected).isEmpty)

        let observer = Task {
            await model.observeChanges(catalog: catalog, settings: settings, events: events)
        }
        try await waitUntil { settings.subscriberCount == 1 }
        try await settings.setDeny("com.alpha")
        try await waitUntil { model.deniedIds.contains("com.alpha") }

        #expect(model.filteredApps(for: .Allowed).isEmpty)
        #expect(model.filteredApps(for: .Rejected).map(\.id) == ["com.alpha"])
        observer.cancel()
    }

    @Test("允许后应用立即回到允许分桶")
    func reloadsAfterAllow() async throws {
        let settings = MockSettings()
        let events = MockEvents(appIdsSince: ["com.alpha"])
        let catalog = StubCatalog()
        let model = AppListModel()

        await model.load(catalog: catalog, settings: settings, events: events)
        try await settings.setDeny("com.alpha")
        await model.load(catalog: catalog, settings: settings, events: events)
        #expect(model.filteredApps(for: .Rejected).map(\.id) == ["com.alpha"])

        let observer = Task {
            await model.observeChanges(catalog: catalog, settings: settings, events: events)
        }
        try await waitUntil { settings.subscriberCount == 1 }
        try await settings.setAllow("com.alpha")
        try await waitUntil { !model.deniedIds.contains("com.alpha") }

        #expect(model.filteredApps(for: .Rejected).isEmpty)
        #expect(model.filteredApps(for: .Allowed).map(\.id) == ["com.alpha"])
        observer.cancel()
    }

    @Test("被禁止的应用置顶")
    func deniedAppsComeFirst() async throws {
        let settings = MockSettings()
        let events = MockEvents(appIdsSince: ["com.alpha", "com.beta"])
        let catalog = StubCatalog()
        let model = AppListModel()

        await model.load(catalog: catalog, settings: settings, events: events)
        try await settings.setDeny("com.beta")
        await model.load(catalog: catalog, settings: settings, events: events)

        #expect(model.filteredApps(for: .All).map(\.id).first == "com.beta")
    }

    private func waitUntil(
        timeout: TimeInterval = 3,
        _ condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        Issue.record("等待条件超时")
    }
}

// MARK: - Mock

/// 规则设置 Mock：支持多订阅者广播。
@MainActor
final class MockSettings: AppSettingsProviding {
    private var denied: Set<String> = []
    private var continuations: [UUID: AsyncStream<AppSettingsChange>.Continuation] = [:]

    func fetchAll() async throws -> [AppSettingSnapshot] {
        denied.map { AppSettingSnapshot(appId: $0, allowed: false) }
    }

    func find(_ appId: String) async throws -> AppSettingSnapshot? {
        denied.contains(appId) ? AppSettingSnapshot(appId: appId, allowed: false) : nil
    }

    func deniedApps() async throws -> [AppSettingSnapshot] {
        denied.map { AppSettingSnapshot(appId: $0, allowed: false) }
    }

    func deniedAppsCount() async throws -> Int { denied.count }

    /// 当前订阅者数量（等待订阅建立用）。
    var subscriberCount: Int { continuations.count }

    func shouldAllow(_ appId: String) async -> Bool { !denied.contains(appId) }

    func shouldAllowSync(_ appId: String) -> Bool { !denied.contains(appId) }

    func setAllow(_ appId: String) async throws {
        denied.remove(appId)
        notify(.didAllow(appId: appId))
    }

    func setDeny(_ appId: String) async throws {
        denied.insert(appId)
        notify(.didDeny(appId: appId))
    }

    func delete(_ appId: String) async throws {
        denied.remove(appId)
    }

    func observeChanges() -> AsyncStream<AppSettingsChange> {
        let id = UUID()
        return AsyncStream { continuation in
            continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.continuations[id] = nil
                }
            }
        }
    }

    private func notify(_ change: AppSettingsChange) {
        continuations.values.forEach { $0.yield(change) }
    }
}

/// 事件存储 Mock：提供本次会话中出现过事件的应用 ID。
@MainActor
final class MockEvents: FirewallEventsProviding {
    private let appIds: [String]

    init(appIdsSince: [String]) {
        self.appIds = appIdsSince
    }

    var sessionAppIds: [String] { appIds }

    func observeSessionAppIds() -> AsyncStream<[String]> {
        AsyncStream { continuation in
            continuation.yield(appIds)
            continuation.finish()
        }
    }

    func fetchPage(_ query: FirewallEventQuery) async throws -> FirewallEventPage {
        FirewallEventPage(events: [], totalCount: 0, page: query.page, pageSize: query.pageSize)
    }

    func count(_ query: FirewallEventCountQuery) async throws -> Int { 0 }
    func totalCount() async throws -> Int { 0 }
    func allAppIds() async throws -> [String] { appIds }
    func fetchByTimeRange(from: Date, to: Date, appIdentifier: String?) async throws -> [FirewallEventSnapshot] { [] }
    func appIdsSince(_ date: Date) async throws -> [String] { appIds }
    func create(_ event: FirewallEventSnapshot) async throws {}
    func deleteByAppId(_ appId: String) async throws {}
    func deleteAll() async throws -> Int { 0 }
    func cleanupOlderThan(days: Int) async throws -> Int { 0 }
    func triggerMaintenance() async throws -> FirewallMaintenanceResult { FirewallMaintenanceResult() }
    func observeChanges() -> AsyncStream<FirewallEventChange> { AsyncStream { _ in } }
}
