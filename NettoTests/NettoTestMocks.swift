import KernelCore
import LumiFactory
import ProviderAppSettings
import ProviderFirewall
import ProviderShell
import SwiftUI

/// 测试用 Mock 契约：记录插件启动顺序 / 失败 / 异步生命周期。
@MainActor
protocol MarkerProviding: Sendable {
    var marker: String { get }
}

@MainActor
final class MarkerProvider: MarkerProviding {
    let marker: String
    init(marker: String) { self.marker = marker }
}

/// 记录启动顺序的 Mock 插件。
@MainActor
class MockPlugin: SuperPlugin {
    let id: String
    var order: Int
    var dependencies: [String]
    let metadata: PluginMetadata
    let marker: String
    var bootError: Error?
    var registerProvider = true
    var events: [String] = []

    init(id: String, order: Int = 200, dependencies: [String] = [], marker: String) {
        self.id = id
        self.order = order
        self.dependencies = dependencies
        self.marker = marker
        self.metadata = PluginMetadata(id: id, name: id, version: "1.0", policy: .enabledByDefault)
    }

    func onBoot(kernel: KernelCoreContainer) throws {
        events.append("boot:\(id)")
        if let bootError { throw bootError }
        if registerProvider {
            try kernel.registerProvider(MarkerProviding.self, MarkerProvider(marker: marker))
        }
    }

    func onReady(kernel: KernelCoreContainer) throws {
        events.append("ready:\(id)")
    }
}

/// 实现异步生命周期的 Mock 插件。
@MainActor
final class AsyncMockPlugin: MockPlugin, AsyncSuperPlugin {
    override func onBoot(kernel: KernelCoreContainer) throws {
        events.append("syncBootCalled:\(id)")
        try super.onBoot(kernel: kernel)
    }

    func onBootAsync(kernel: KernelCoreContainer) async throws {
        events.append("bootAsync:\(id)")
        try kernel.registerProvider(MarkerProviding.self, MarkerProvider(marker: marker))
    }
}

/// 仪表盘贡献测试需要的应用设置 Mock 契约（真实功能由 PluginAppSettings 提供）。
@MainActor
final class TestAppSettingsProvider: AppSettingsProviding {
    func fetchAll() async throws -> [AppSettingSnapshot] { [] }
    func find(_ appId: String) async throws -> AppSettingSnapshot? { nil }
    func deniedApps() async throws -> [AppSettingSnapshot] { [] }
    func deniedAppsCount() async throws -> Int { 0 }
    func shouldAllow(_ appId: String) async -> Bool { true }
    func shouldAllowSync(_ appId: String) -> Bool { true }
    func setAllow(_ appId: String) async throws {}
    func setDeny(_ appId: String) async throws {}
    func delete(_ appId: String) async throws {}
    func observeChanges() -> AsyncStream<AppSettingsChange> { AsyncStream { _ in } }
}

/// 仪表盘贡献测试需要的防火墙 Mock 契约（真实功能由 PluginFirewall 提供）。
@MainActor
final class TestFirewallProvider: FirewallProviding {
    let snapshot = FirewallSnapshot(state: .stopped)

    func refresh() async {}
    func installSystemExtension() async {}
    func installFilter() async throws {}
    func start() async throws {}
    func stop() async throws {}
    func observe() -> AsyncStream<FirewallSnapshot> {
        AsyncStream { continuation in
            continuation.yield(snapshot)
            continuation.finish()
        }
    }
}

/// 行为测试用的最小清单构造器（基线 Provider 仍由共享装配引擎注册）。
@MainActor
enum NettoTestManifest {
    static func identity() -> HostIdentity {
        HostIdentity(
            appName: "TravelMode",
            loggerSubsystem: "com.yueyi.TravelMode.tests",
            mainWindowID: ShellWindowID.main,
            settingsWindowID: ShellWindowID.settings,
            accessibilityPrefix: "netto"
        )
    }

    /// 仅 Mock 插件的最小清单。
    static func minimal(plugins: [any SuperPlugin]) -> HostManifest {
        HostManifest(
            identity: identity(),
            makePlugins: { plugins },
            storage: HostStorageConfiguration(stateStorePluginID: "com.yueyi.TravelMode.plugin-manager")
        )
    }

    /// 仪表盘贡献测试清单：Shell 五契约 + 防火墙 / 应用设置 Mock 契约。
    static func dashboard(plugins: [any SuperPlugin]) -> HostManifest {
        var manifest = minimal(plugins: plugins)
        manifest.registerProviders = { kernel in
            let shell = ShellCenter()
            try kernel.registerProvider(ShellToolbarProviding.self, shell)
            try kernel.registerProvider(SettingsProviding.self, shell)
            try kernel.registerProvider(WindowProviding.self, shell)
            try kernel.registerProvider(WindowRoutingProviding.self, shell)
            try kernel.registerProvider(ProviderShell.ToastProviding.self, shell)
            try kernel.registerProvider(FirewallProviding.self, TestFirewallProvider())
            try kernel.registerProvider(AppSettingsProviding.self, TestAppSettingsProvider())
        }
        return manifest
    }
}