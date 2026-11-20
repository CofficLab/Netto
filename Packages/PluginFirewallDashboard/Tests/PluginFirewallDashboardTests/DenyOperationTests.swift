import Foundation
import ProviderAppSettings
import ProviderShell
import ProviderStore
import Testing
@testable import PluginFirewallDashboard

/// 禁止联网的生产流程：达到免费版限制时必须写入引导状态并给出可见错误提示。
@MainActor
@Suite("禁止联网流程")
struct DenyOperationTests {

    @Test("达到上限时不写规则并提示升级")
    func atLimitDoesNotWriteRule() async throws {
        let settings = RecordingAppSettings(deniedCount: 5)
        let ui = UIProvider()
        ui.selectApp("com.example.app")
        let shell = ShellCenter()

        let outcome = try await DenyOperation(
            repo: settings,
            entitlement: .none,
            ui: ui,
            shell: shell,
            appId: "com.example.app"
        ).run()

        guard case .upgradeRequired(let message) = outcome else {
            Issue.record("达到上限时应要求升级，实际为 \(String(describing: outcome))")
            return
        }
        #expect(settings.deniedAppIds.isEmpty)
        #expect(ui.showsUpgradeOverlay)
        #expect(shell.lastToast?.isError == true)
        #expect(shell.lastToast?.description == message)
    }

    @Test("未达上限时写入规则并通知列表刷新")
    func belowLimitWritesRule() async throws {
        let settings = RecordingAppSettings(deniedCount: 1)
        let ui = UIProvider()
        ui.selectApp("com.example.app")
        let shell = ShellCenter()
        var reloadCount = 0

        let outcome = try await DenyOperation(
            repo: settings,
            entitlement: .none,
            ui: ui,
            shell: shell,
            appId: "com.example.app",
            onRuleChange: { reloadCount += 1 }
        ).run()

        #expect(outcome == .denied)
        #expect(settings.deniedAppIds == ["com.example.app"])
        #expect(reloadCount == 1)
        #expect(ui.showsUpgradeOverlay == false)
        #expect(shell.lastToast?.isError == false)
    }

    @Test("Pro 用户不受上限限制")
    func proUserBypassesLimit() async throws {
        let settings = RecordingAppSettings(deniedCount: 99)
        let ui = UIProvider()
        let shell = ShellCenter()

        let outcome = try await DenyOperation(
            repo: settings,
            entitlement: StoreEntitlementSnapshot(tier: .pro, expiresAt: Date().addingTimeInterval(3600)),
            ui: ui,
            shell: shell,
            appId: "com.example.app"
        ).run()

        #expect(outcome == .denied)
        #expect(settings.deniedAppIds == ["com.example.app"])
    }
}

/// 记录规则写入的应用设置假实现。
@MainActor
final class RecordingAppSettings: AppSettingsProviding {
    var deniedCount: Int
    private(set) var deniedAppIds: [String] = []
    private var continuation: AsyncStream<AppSettingsChange>.Continuation?

    init(deniedCount: Int) {
        self.deniedCount = deniedCount
    }

    func fetchAll() async throws -> [AppSettingSnapshot] { [] }
    func find(_ appId: String) async throws -> AppSettingSnapshot? { nil }
    func deniedApps() async throws -> [AppSettingSnapshot] { [] }
    func deniedAppsCount() async throws -> Int { deniedCount }
    func shouldAllow(_ appId: String) async -> Bool { true }
    func shouldAllowSync(_ appId: String) -> Bool { true }
    func setAllow(_ appId: String) async throws {}
    func setDeny(_ appId: String) async throws {
        deniedAppIds.append(appId)
    }
    func delete(_ appId: String) async throws {}

    func observeChanges() -> AsyncStream<AppSettingsChange> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }
}
