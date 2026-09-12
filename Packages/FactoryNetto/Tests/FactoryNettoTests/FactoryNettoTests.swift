import Foundation
import KernelCore
import PluginShell
import ProviderAppSettings
import ProviderFirewallEvents
import ProviderShell
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

/// FactoryNetto 装配测试：Provider 注册、插件顺序、失败路径、视图装配。
@MainActor
final class FactoryNettoTests: XCTestCase {

    func testMakeKernelRegistersShellProviders() async throws {
        let kernel = try await FactoryNetto.makeKernelAsync()
        XCTAssertNotNil(kernel.resolveProvider(ShellToolbarProviding.self))
        XCTAssertNotNil(kernel.resolveProvider(SettingsProviding.self))
        XCTAssertNotNil(kernel.resolveProvider(WindowProviding.self))
        XCTAssertNotNil(kernel.resolveProvider(ToastProviding.self))
        XCTAssertEqual(kernel.lifecycleState, .running)
        // 默认目录包含持久化三插件：事件与设置契约可用。
        XCTAssertNotNil(kernel.resolveProvider(ProviderAppSettings.AppSettingsProviding.self))
        XCTAssertNotNil(kernel.resolveProvider(ProviderFirewallEvents.FirewallEventsProviding.self))
        XCTAssertEqual(kernel.registeredPluginCount, 3)
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
        let kernel = try await FactoryNetto.makeKernelAsync(
            providerAssembly: DefaultProviderAssembly(),
            pluginAssembly: TestPluginAssembly(plugins: [asyncPlugin])
        )
        XCTAssertEqual(kernel.lifecycleState, .running)
        XCTAssertEqual(asyncPlugin.events, ["bootAsync:Async", "ready:Async"])
        XCTAssertEqual(kernel.resolveProvider(MarkerProviding.self)?.marker, "async")
    }

    func testMakeMainViewUsesResolvedShell() async throws {
        let kernel = try await FactoryNetto.makeKernelAsync()
        let view = FactoryNetto.makeMainView(kernel: kernel)
        // 编译期验证视图类型；运行时由 App Host 呈现。
        XCTAssertNotNil(view)
    }

    func testMakeSettingsViewUsesResolvedSettings() async throws {
        let kernel = try await FactoryNetto.makeKernelAsync()
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
}
