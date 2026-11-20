import AppKit
import Foundation
import ProviderAppSettings
import ProviderFirewall
import ProviderShell
import SwiftUI
import Testing
@testable import PluginFirewallDashboard

/// 菜单栏弹窗头部：被阻止应用数量必须实时反映规则变化。
@MainActor
@Suite("菜单栏弹窗头部")
struct MenuBarPopoverHeaderTests {

    @Test("规则变化后被阻止数量实时更新")
    func deniedCountFollowsRuleChanges() async throws {
        let settings = FakeAppSettings()
        settings.deniedCount = 2

        let model = MenuBarDeniedAppsModel(settings: settings)
        model.start()

        try await waitUntil { model.deniedCount == 2 }

        settings.deniedCount = 4
        settings.notifyChange()

        try await waitUntil { model.deniedCount == 4 }
    }

    @Test("弹窗视图观察被阻止数量模型")
    func popoverObservesDeniedCountModel() {
        let settings = FakeAppSettings()
        let model = MenuBarDeniedAppsModel(settings: settings)
        let view = FirewallMenuBarPopoverView(firewall: FakeFirewallProvider(), deniedApps: model)

        // 视图必须以观察者的方式持有模型，否则头部副标题不会随规则变化刷新。
        let children = Mirror(reflecting: view).children
        #expect(children.contains { $0.label == "_deniedApps" })
    }

    private func waitUntil(
        timeout: TimeInterval = 3,
        _ condition: @MainActor () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        Issue.record("等待条件超时")
    }
}

/// 可控的应用设置假实现。
@MainActor
final class FakeAppSettings: AppSettingsProviding {
    var deniedCount = 0
    private var continuation: AsyncStream<AppSettingsChange>.Continuation?

    func fetchAll() async throws -> [AppSettingSnapshot] { [] }
    func find(_ appId: String) async throws -> AppSettingSnapshot? { nil }
    func deniedApps() async throws -> [AppSettingSnapshot] { [] }
    func deniedAppsCount() async throws -> Int { deniedCount }
    func shouldAllow(_ appId: String) async -> Bool { true }
    func shouldAllowSync(_ appId: String) -> Bool { true }
    func setAllow(_ appId: String) async throws {}
    func setDeny(_ appId: String) async throws {}
    func delete(_ appId: String) async throws {}

    func observeChanges() -> AsyncStream<AppSettingsChange> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func notifyChange() {
        continuation?.yield(.didDeny(appId: "com.example.app"))
    }
}

/// 防火墙能力假实现。
@MainActor
final class FakeFirewallProvider: FirewallProviding {
    var snapshot: FirewallSnapshot { FirewallSnapshot(state: .stopped) }
    func refresh() async {}
    func installSystemExtension() async {}
    func installFilter() async throws {}
    func start() async throws {}
    func stop() async throws {}
    func observe() -> AsyncStream<FirewallSnapshot> {
        AsyncStream { $0.finish() }
    }
}
