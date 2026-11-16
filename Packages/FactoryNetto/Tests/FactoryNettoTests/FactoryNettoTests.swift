import Foundation
import KernelCore
import PluginBrandLogo
import PluginFirewallDashboard
import PluginPersistence
import ProviderRootView
import ProviderShell
import ProviderAppSettings
import ProviderFirewall
import ProviderFirewallEvents
import ProviderSettingView
import ProviderTheme
import ProviderToolbar
import ProviderMenuBar
import ProviderLogo
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
private final class AsyncMockPlugin: MockPlugin, AsyncSuperPlugin {
    override func onBoot(kernel: KernelCoreContainer) throws {
        events.append("syncBootCalled:\(id)")
        try super.onBoot(kernel: kernel)
    }

    func onBootAsync(kernel: KernelCoreContainer) async throws {
        events.append("bootAsync:\(id)")
        try kernel.registerProvider(MarkerProviding.self, MarkerProvider(marker: marker))
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

/// 仪表盘贡献测试需要的契约；真实功能由 PluginFirewall / PluginAppSettings 提供。
@MainActor
private struct DashboardTestProviderAssembly: ProviderAssembling {
    func registerProviders(into kernel: KernelCoreContainer) throws {
        try DefaultProviderAssembly().registerProviders(into: kernel)
        try kernel.registerProvider(FirewallProviding.self, TestFirewallProvider())
        try kernel.registerProvider(AppSettingsProviding.self, TestAppSettingsProvider())
    }
}

@MainActor
private final class TestAppSettingsProvider: AppSettingsProviding {
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

@MainActor
private final class TestFirewallProvider: FirewallProviding {
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
        XCTAssertNotNil(kernel.resolveProvider((any ToolbarProviding).self))
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
            // KernelCore 会把生命周期错误包装成 pluginLifecycleFailed，附带
            // 归属信息（插件 ID + 阶段），底层错误保留在 underlying 里。
            guard case KernelCoreError.pluginLifecycleFailed(let pluginID, let phase, let underlying)? =
                error as? KernelCoreError
            else {
                XCTFail("期望 pluginLifecycleFailed，实际是 \(error)")
                return
            }
            XCTAssertEqual(pluginID, "F")
            XCTAssertEqual(phase, "boot")
            XCTAssertEqual((underlying as NSError).domain, "test")
            XCTAssertEqual((underlying as NSError).code, 1)
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
            providerAssembly: DashboardTestProviderAssembly(),
            pluginAssembly: TestPluginAssembly(plugins: dependencies + [dashboard])
        )
        let menuBar = try XCTUnwrap(kernel.resolveProvider(MenuBarProviding.self))
        XCTAssertTrue(menuBar.contentItems.isEmpty)
        XCTAssertEqual(menuBar.popupItems.map(\.id), ["firewall-dashboard"])

        try await kernel.disablePlugin(id: dashboard.id)
        XCTAssertTrue(menuBar.contentItems.isEmpty)
        XCTAssertTrue(menuBar.popupItems.isEmpty)

        try await kernel.enablePlugin(id: dashboard.id)
        XCTAssertTrue(menuBar.contentItems.isEmpty)
        XCTAssertEqual(menuBar.popupItems.map(\.id), ["firewall-dashboard"])

        try await kernel.stopAsync()
        XCTAssertTrue(menuBar.contentItems.isEmpty)
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
        try kernel.registerProvider(SettingViewProviding.self, provider)

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

    /// 菜单栏品牌图标由插件贡献：宿主装配注册 `LogoProviding`，插件在
    /// `onBoot` 追加 `LogoItem`，状态栏取最高优先级项（无贡献时退回 App 资源）。
    func testBrandLogoPluginContributesMenuBarLogo() async throws {
        let kernel = try await FactoryNetto.makeKernelAsync(
            providerAssembly: DefaultProviderAssembly(),
            pluginAssembly: TestPluginAssembly(plugins: [])
        )
        let logo = try XCTUnwrap(kernel.resolveProvider((any LogoProviding).self))
        XCTAssertNil(logo.highestPriorityLogoItem, "没有 Logo 插件时不应有贡献")

        try BrandLogoPlugin().onBoot(kernel: kernel)

        XCTAssertEqual(logo.highestPriorityLogoItem?.id, "brand-logo")
        // 状态栏视图可正常构造（Logo 项视图在状态栏尺寸内渲染）。
        _ = FactoryNetto.makeStatusBarView(
            kernel: kernel,
            brandImage: Image(systemName: "shield")
        )
    }

    func testDefaultPluginAssemblyIncludesBrandLogo() {
        let ids = DefaultPluginAssembly().makePlugins().map(\.id)

        XCTAssertTrue(ids.contains("brand-logo"), "默认装配应包含品牌 Logo 插件：\(ids)")
        XCTAssertTrue(
            ids.contains(DefaultPluginAssembly.rootViewConfiguration.pluginID),
            "默认装配应包含根视图插件：\(ids)"
        )
    }

    /// 工具栏设置按钮：宿主贡献的 `settings` 项位于 trailing，点击发出标准的
    /// 「打开设置」通知（由常驻 `SettingsWindowRouter` 打开设置窗口）。
    func testToolbarSettingsItemRoutesToSettingsNotification() throws {
        let item = NettoToolbarSettings.makeItem()

        XCTAssertEqual(item.id, "settings")
        XCTAssertEqual(item.placement, .trailing)
        XCTAssertEqual(item.category, .global)
        XCTAssertEqual(item.order, 300)
        XCTAssertNotNil(item.makeView())
    }

    /// 生产装配完成后，共享根视图的工具栏包含防火墙控件与宿主设置按钮，
    /// 内容区已注入仪表盘 —— 主窗口与 Wakey / Lumi 走同一套体系。
    func testDefaultAssemblyWiresMainWindowRootView() async throws {
        let container = try PersistenceService.inMemoryContainer()
        let plugins = DefaultPluginAssembly().makePlugins().map { plugin -> any SuperPlugin in
            if plugin is PersistencePlugin {
                return PersistencePlugin(container: container)
            }
            return plugin
        }
        let kernel = try await FactoryNetto.makeKernelAsync(
            pluginAssembly: TestPluginAssembly(plugins: plugins)
        )

        let rootView = try XCTUnwrap(kernel.resolveProvider((any RootViewProviding).self))
        let toolbar = try XCTUnwrap(kernel.resolveProvider((any ToolbarProviding).self))

        XCTAssertEqual(toolbar.visibleToolbarItems.map(\.id), ["switcher", "filter", "settings"])
        XCTAssertNotNil(rootView.view(for: .toolbar), "工具栏应已接入根视图")
        XCTAssertNotNil(rootView.view(for: .content), "内容区应已注入仪表盘")
    }

    /// 生产插件目录启动后，菜单栏品牌 Logo 由 `brand-logo` 插件提供。
    func testDefaultAssemblyContributesBrandLogoItem() async throws {
        let container = try PersistenceService.inMemoryContainer()
        let plugins = DefaultPluginAssembly().makePlugins().map { plugin -> any SuperPlugin in
            if plugin is PersistencePlugin {
                return PersistencePlugin(container: container)
            }
            return plugin
        }
        let kernel = try await FactoryNetto.makeKernelAsync(
            pluginAssembly: TestPluginAssembly(plugins: plugins)
        )
        let logo = try XCTUnwrap(kernel.resolveProvider((any LogoProviding).self))

        XCTAssertEqual(logo.highestPriorityLogoItem?.id, "brand-logo")
    }

    private func makeIsolatedKernel() async throws -> KernelCoreContainer {
        try await FactoryNetto.makeKernelAsync(
            providerAssembly: DefaultProviderAssembly(),
            pluginAssembly: TestPluginAssembly(plugins: [])
        )
    }

    /// 设置窗口默认选中规则（回归测试）：全新启动（默认装配）后应选中
    /// order 最小的入口。
    ///
    /// 背景：`addEntries` 会走 `registerEntries`，其"选中为空则锁定为当时列表
    /// 第一个"的语义会让**最先注册入口的插件**意外成为默认选中（Wakey/Lumi/
    /// GitOK/Kuzee 均已踩坑并在各自内核启动后重置），本测试验证 Netto。
    func testSettingsDefaultsToFirstEntryByOrder() async throws {
        // 默认插件装配里的 PersistencePlugin 会按生产配置创建
        // ~/Documents/debug/db.sqlite；单元测试进程没有 App 沙箱容器，
        // 会在 ModelContainer 创建时 fatalError。这里改注入内存容器。
        let container = try PersistenceService.inMemoryContainer()
        let defaultPlugins = DefaultPluginAssembly().makePlugins().map { plugin -> any SuperPlugin in
            if plugin is PersistencePlugin {
                return PersistencePlugin(container: container)
            }
            return plugin
        }
        let kernel = try await FactoryNetto.makeKernelAsync(
            pluginAssembly: TestPluginAssembly(plugins: defaultPlugins)
        )
        let settings = try XCTUnwrap(kernel.resolveProvider((any SettingViewProviding).self))

        XCTAssertFalse(settings.entries.isEmpty, "设置入口应在内核启动后完成注册")
        let orders = settings.entries.map(\.order)
        XCTAssertEqual(orders, orders.sorted(), "entries must be sorted by order ascending")

        print("NETTO-ENTRIES: \(settings.entries.map { "\($0.id)#\($0.order)" }.joined(separator: ", "))")
        print("NETTO-SELECTED: \(settings.selectedEntryID ?? "nil")")

        XCTAssertEqual(
            settings.selectedEntryID, settings.entries.first?.id,
            "默认应选中 \(settings.entries.first?.id ?? "nil")，实际为 \(settings.selectedEntryID ?? "nil")"
        )
    }
}
