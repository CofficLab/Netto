import Foundation
import ProviderAppSettings
import ProviderFirewall
import ProviderFirewallEvents
import ProviderStore
import SwiftUI
import Testing
@testable import ProviderViewEnvironment

// MARK: - 最小 Mock

/// 最小防火墙契约 Mock：仅需满足 EnvironmentValues 存取测试。
@MainActor
private final class StubFirewall: FirewallProviding {
    var snapshot = FirewallSnapshot(state: .running)
    func refresh() async {}
    func installSystemExtension() async {}
    func installFilter() async throws {}
    func start() async throws {}
    func stop() async throws {}
    func observe() -> AsyncStream<FirewallSnapshot> { AsyncStream { $0.finish() } }
}

/// 最小事件存储契约 Mock。
@MainActor
private final class StubEvents: FirewallEventsProviding {
    func fetchPage(_ query: FirewallEventQuery) async throws -> FirewallEventPage {
        FirewallEventPage(events: [], totalCount: 0, page: query.page, pageSize: query.pageSize)
    }
    func count(_ query: FirewallEventCountQuery) async throws -> Int { 0 }
    func totalCount() async throws -> Int { 0 }
    func allAppIds() async throws -> [String] { [] }
    func fetchByTimeRange(from: Date, to: Date, appIdentifier: String?) async throws -> [FirewallEventSnapshot] { [] }
    func appIdsSince(_ date: Date) async throws -> [String] { [] }
    func create(_ event: FirewallEventSnapshot) async throws {}
    func deleteByAppId(_ appId: String) async throws {}
    func deleteAll() async throws -> Int { 0 }
    func cleanupOlderThan(days: Int) async throws -> Int { 0 }
    func triggerMaintenance() async throws -> FirewallMaintenanceResult { FirewallMaintenanceResult() }
    func observeChanges() -> AsyncStream<FirewallEventChange> { AsyncStream { $0.finish() } }
}

/// 最小设置契约 Mock。
@MainActor
private final class StubSettings: AppSettingsProviding {
    func fetchAll() async throws -> [AppSettingSnapshot] { [] }
    func find(_ appId: String) async throws -> AppSettingSnapshot? { nil }
    func deniedApps() async throws -> [AppSettingSnapshot] { [] }
    func deniedAppsCount() async throws -> Int { 0 }
    func shouldAllow(_ appId: String) async -> Bool { true }
    func shouldAllowSync(_ appId: String) -> Bool { true }
    func setAllow(_ appId: String) async throws {}
    func setDeny(_ appId: String) async throws {}
    func delete(_ appId: String) async throws {}
    func observeChanges() -> AsyncStream<AppSettingsChange> { AsyncStream { $0.finish() } }
}

/// 最小 Store 契约 Mock。
@MainActor
private final class StubStore: StoreProviding {
    var entitlement = StoreEntitlementSnapshot(tier: .pro, expiresAt: Date(timeIntervalSinceNow: 3600))
    func loadProducts() async throws -> [StoreProductSnapshot] { [] }
    func purchase(_ productID: String) async throws {}
    func restore() async throws {}
    func observeEntitlement() -> AsyncStream<StoreEntitlementSnapshot> { AsyncStream { $0.finish() } }
}

// MARK: - 测试

/// `EnvironmentValues` Provider 注入键测试。
///
/// 生产路径由 AppEnvironment 在启动期注入；未装配时必须为 nil，
/// 视图据此走「启动失败 / 未运行」分支，因此默认值本身是契约的一部分。
@MainActor
@Suite("EnvironmentValues Provider 注入")
struct ViewEnvironmentTests {

    // MARK: - 默认值

    @Test("未装配时四个 Provider 均为 nil")
    func providersDefaultToNil() {
        let values = EnvironmentValues()
        #expect(values.firewallProvider == nil)
        #expect(values.eventsProvider == nil)
        #expect(values.settingsProvider == nil)
        #expect(values.storeProvider == nil)
    }

    @Test("sessionStartDate 默认非 nil")
    func sessionStartDateHasDefault() {
        let values = EnvironmentValues()
        #expect(values.sessionStartDate.timeIntervalSinceNow.magnitude < 5)
    }

    // MARK: - 读写往返

    @Test("firewallProvider 写入后可读回同一实例")
    func firewallRoundTrip() {
        let stub = StubFirewall()
        var values = EnvironmentValues()
        values.firewallProvider = stub
        #expect(values.firewallProvider === stub)
    }

    @Test("eventsProvider 写入后可读回同一实例")
    func eventsRoundTrip() {
        let stub = StubEvents()
        var values = EnvironmentValues()
        values.eventsProvider = stub
        #expect(values.eventsProvider === stub)
    }

    @Test("settingsProvider 写入后可读回同一实例")
    func settingsRoundTrip() {
        let stub = StubSettings()
        var values = EnvironmentValues()
        values.settingsProvider = stub
        #expect(values.settingsProvider === stub)
    }

    @Test("storeProvider 写入后可读回同一实例")
    func storeRoundTrip() {
        let stub = StubStore()
        var values = EnvironmentValues()
        values.storeProvider = stub
        #expect(values.storeProvider === stub)
    }

    @Test("sessionStartDate 写入后精确读回")
    func sessionStartDateRoundTrip() {
        let fixed = Date(timeIntervalSince1970: 1_700_000_000)
        var values = EnvironmentValues()
        values.sessionStartDate = fixed
        #expect(values.sessionStartDate == fixed)
    }

    @Test("各 Provider 互相独立：写入其中一个不影响其他")
    func providersAreIndependent() {
        var values = EnvironmentValues()
        values.firewallProvider = StubFirewall()
        #expect(values.eventsProvider == nil)
        #expect(values.settingsProvider == nil)
        #expect(values.storeProvider == nil)

        values.eventsProvider = StubEvents()
        #expect(values.firewallProvider != nil, "已写入的 firewall 不应被其他键覆盖")
        #expect(values.eventsProvider != nil)
    }

    @Test("覆盖为 nil 回到未装配状态")
    func resettingToNil() {
        var values = EnvironmentValues()
        values.firewallProvider = StubFirewall()
        values.firewallProvider = nil
        #expect(values.firewallProvider == nil)
    }
}
