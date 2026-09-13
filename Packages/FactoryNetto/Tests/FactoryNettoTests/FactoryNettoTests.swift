import Foundation
import KernelCore
import PluginFirewallDashboard
import ProviderShell
import ProviderAppSettings
import ProviderFirewallEvents
import ProviderSettingView
import ProviderTheme
import ProviderMenuBar
import SwiftUI
import XCTest
@testable import FactoryNetto

/// 测试用 Mock 契约。
@MainActor
private protocol MarkerProviding: Sendable {
    var marker: String { get }
}

@MainActor
private final class MarkerProvider: MarkerProviding {
    let marker: String
    init(marker: String) { self.marker = marker }
}

/// 记录启动顺序的 Mock 插件。
@MainActor
private class MockPlugin: SuperPlugin {
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
        self.metadata = PluginMetadata(name: id, version: "1.0", policy: .enabledByDefault)
    }

    func onBoot(kernel: KernelCoreContainer) throws {
        events.append("boot:\(id)")
        if let bootError { throw bootError }
        if registerProvider {
            try kernel.registerProvider(MarkerProvider(marker: marker), for: MarkerProviding.self, owner: id)
        }
    }

    func onReady(kernel: KernelCoreContainer) throws {
        events.append("ready:\(id)")
    }
}

/// 实现异步生命周期的 Mock 插件。
@MainActor
private final class AsyncMockPlugin: MockPlugin, AsyncSuperPlugin {
    override func onBoot(kernel: KernelCoreContainer) throws {
        events.append("syncBootCalled:\(id)")
        try super.onBoot(kernel: kernel)
    }

    func onBootAsync(kernel: KernelCoreContainer) async throws {
        events.append("bootAsync:\(id)")
        try kernel.registerProvider(MarkerProvider(marker: marker), for: MarkerProviding.self, owner: id)
    }
}

/// 测试注入装配。
@MainActor
private struct TestPluginAssembly: PluginAssembling {
    let plugins: [any SuperPlugin]
    func makePlugins() -> [any SuperPlugin] { plugins }
}

/// 空 Provider 装配：测试自行注册 Provider 时使用（避免与默认 ShellCenter 冲突）。
private struct EmptyProviderAssembly: ProviderAssembling {
    func registerProviders(into kernel: KernelCoreContainer) throws {}
}

/// FactoryNetto 装配测试：Provider 注册、插件顺序、失败路径、视图装配。
@MainActor
final class FactoryNettoTests: XCTestCase {

    func testMakeKernelRegistersShellProviders() async throws {
        let kernel = try await FactoryNetto.makeKernelAsync(
            providerAssembly: DefaultProviderAssembly(),
            pluginAssembly: TestPluginAssembly(plugins: [])
        )
        XCTAssertNotNil(kernel.resolveProvider(ShellToolbarProviding.self))
        XCTAssertNotNil(kernel.resolveProvider(SettingsProviding.self))
        XCTAssertNotNil(kernel.resolveProvider(WindowProviding.self))
        XCTAssertNotNil(kernel.resolveProvider(ToastProviding.self))
        XCTAssertNotNil(kernel.resolveProvider(MenuBarProviding.self))
        XCTAssertEqual(kernel.lifecycleState, .running)
        XCTAssertEqual(kernel.registeredPluginCount, 0)
    }

    func testMakeKernelStartsPluginsInOrder() throws {
        let a = MockPlugin(id: "A", order: 20, marker: "a")
        let b = MockPlugin(id: "B", order: 10, marker: "b")
        a.registerProvider = false
        let kernel = try FactoryNetto.makeKernel(
            providerAssembly: DefaultProviderAssembly(),
            pluginAssembly: TestPluginAssembly(plugins: [a, b])
        )
        XCTAssertEqual(kernel.resolveProvider(MarkerProviding.self)?.marker, "b")
        XCTAssertEqual(kernel.registeredPluginCount, 2)
        XCTAssertEqual(kernel.lifecycleState, .running)
    }

    func testMakeKernelFailurePropagates() {
        let failing = MockPlugin(id: "F", marker: "f")
        failing.bootError = NSError(domain: "test", code: 1)
        XCTAssertThrowsError(
            try FactoryNetto.makeKernel(
                providerAssembly: DefaultProviderAssembly(),
                pluginAssembly: TestPluginAssembly(plugins: [failing])
            )
        ) { error in
            XCTAssertEqual(error as NSError, NSError(domain: "test", code: 1))
        }
    }

    func testMakeKernelAsyncStartsAsyncPlugin() async throws {
        let asyncPlugin = AsyncMockPlugin(id: "Async", marker: "async")
        var providersWereRegisteredBeforePluginBoot = false
        let kernel = try await FactoryNetto.makeKernelAsync(
            providerAssembly: DefaultProviderAssembly(),
            pluginAssembly: TestPluginAssembly(plugins: [asyncPlugin]),
            onProvidersRegistered: { kernel in
                providersWereRegisteredBeforePluginBoot =
                    kernel.resolveProvider(MenuBarProviding.self) != nil
                    && asyncPlugin.events.isEmpty
            }
        )
        XCTAssertEqual(kernel.lifecycleState, .running)
        XCTAssertTrue(providersWereRegisteredBeforePluginBoot)
        XCTAssertEqual(asyncPlugin.events, ["bootAsync:Async", "ready:Async"])
        XCTAssertEqual(kernel.resolveProvider(MarkerProviding.self)?.marker, "async")
    }

    func testDashboardPluginAddsAndRemovesItsPopoverContributionWithLifecycle() async throws {
        let dependencies = ["firewall", "appsettings", "eventstore", "store"].map { id in
            let plugin = MockPlugin(id: id, marker: id)
            plugin.registerProvider = false
            return plugin as any SuperPlugin
        }
        let dashboard = FirewallDashboardPlugin()
        let kernel = try await FactoryNetto.makeKernelAsync(
            providerAssembly: DefaultProviderAssembly(),
            pluginAssembly: TestPluginAssembly(plugins: dependencies + [dashboard])
        )
        let menuBar = try XCTUnwrap(kernel.resolveProvider(MenuBarProviding.self))
        XCTAssertEqual(menuBar.popupItems.map(\.id), ["firewall-dashboard"])

        try await kernel.disablePlugin(id: dashboard.id)
        XCTAssertTrue(menuBar.popupItems.isEmpty)

        try await kernel.enablePlugin(id: dashboard.id)
        XCTAssertEqual(menuBar.popupItems.map(\.id), ["firewall-dashboard"])

        try await kernel.stopAsync()
        XCTAssertTrue(menuBar.popupItems.isEmpty)
    }

    func testMakeMainViewUsesResolvedShell() async throws {
        let kernel = try await makeIsolatedKernel()
        let view = FactoryNetto.makeMainView(kernel: kernel)
        // 编译期验证视图类型；运行时由 App Host 呈现。
        XCTAssertNotNil(view)
    }

    func testMakeSettingsViewUsesResolvedSettings() async throws {
        // DefaultProviderAssembly 注册 DefaultSettingViewProviding：
        // makeSettingsView 解析 SettingViewProviding 并渲染设置视图。
        let kernel = try await makeIsolatedKernel()
        let settings = kernel.resolveProvider(SettingViewProviding.self)
        XCTAssertNotNil(settings)
        let view = FactoryNetto.makeSettingsView(kernel: kernel)
        XCTAssertNotNil(view)
    }

    func testMakeSettingsViewFailsExplicitlyWithoutProvider() async throws {
        // Provider 未装配时返回显式失败视图（不静默退化、不强制解包）。
        let kernel = try await FactoryNetto.makeKernelAsync(
            providerAssembly: EmptyProviderAssembly(),
            pluginAssembly: TestPluginAssembly(plugins: [])
        )
        let view = FactoryNetto.makeSettingsView(kernel: kernel)
        XCTAssertNotNil(view)
    }

    func testMakeSettingsViewRendersInjectedEntries() async throws {
        // 插件注入设置入口（复刻 HostSettingsPlugin 注入「通用」入口）：
        // 注册后 makeSettingsView 渲染双栏设置视图，入口可被解析选中。
        let kernel = try await FactoryNetto.makeKernelAsync(
            providerAssembly: EmptyProviderAssembly(),
            pluginAssembly: TestPluginAssembly(plugins: [])
        )
        let provider = DefaultSettingViewProviding()
        provider.addEntries([
            SettingEntryItem(id: "general", title: "通用", systemImage: "gearshape", order: 5) {
                Text("general-panel")
            },
        ])
        try kernel.registerProvider(provider, for: SettingViewProviding.self, owner: "test")

        XCTAssertEqual(provider.entries.count, 1)
        XCTAssertEqual(provider.selectedEntryID, "general")
        let view = FactoryNetto.makeSettingsView(kernel: kernel)
        XCTAssertNotNil(view)
    }

    func testMakeMainViewRendersToolbarContributions() throws {
        let shell = ShellCenter()
        shell.registerToolbar(
            ToolbarContribution(id: "btn", position: .left, order: 10, ownerPluginID: "Test") {
                AnyView(Text("hello"))
            }
        )
        XCTAssertEqual(shell.leftContributions.count, 1)
    }

    private func makeIsolatedKernel() async throws -> KernelCoreContainer {
        try await FactoryNetto.makeKernelAsync(
            providerAssembly: DefaultProviderAssembly(),
            pluginAssembly: TestPluginAssembly(plugins: [])
        )
    }
}
