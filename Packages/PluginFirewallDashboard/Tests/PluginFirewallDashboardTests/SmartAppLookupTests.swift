import Foundation
import KernelCore
import ProviderFirewall
import ProviderMenuBar
import ProviderShell
import Testing
@testable import PluginFirewallDashboard

/// `SmartApp` 的查找/归类逻辑测试（`Entity/SmartApp*.swift` 中的非视图部分）。
@Suite("SmartApp 查找逻辑")
struct SmartAppLookupTests {

    @Test("getSystemApp：命中内置系统应用目录")
    func getSystemAppFindsCatalogEntry() {
        let known = SmartApp.allSystemApps[0]

        let found = SmartApp.getSystemApp(known.id)

        #expect(found?.id == known.id)
        #expect(found?.name == known.name)
        #expect(found?.isSystemApp == true)
    }

    @Test("getSystemApp：ID 以「.」开头但不在目录中时返回未知系统应用")
    func getSystemAppFallsBackToHiddenSystemApp() {
        let found = SmartApp.getSystemApp(".com.example.notInCatalog")

        #expect(found?.id == ".com.example.notInCatalog")
        #expect(found?.name == "未知系统应用")
        #expect(found?.isSystemApp == true)
        #expect(found?.hidden == true)
    }

    @Test("getSystemApp：普通未知 ID 返回 nil")
    func getSystemAppReturnsNilForOrdinaryID() {
        #expect(SmartApp.getSystemApp("com.example.unknown") == nil)
    }

    @Test("fromId：普通未知 ID 退化为未知应用")
    func fromIdFallsBackToUnknownApp() {
        let app = SmartApp.fromId("com.example.definitely-not-running")

        #expect(app.id == "com.example.definitely-not-running")
        #expect(app.name == "未知")
        #expect(app.isSystemApp == false)
    }

    @Test("fromId：以「.」开头的未知 ID 归为隐藏的系统应用")
    func fromIdTreatsDotPrefixedAsSystemApp() {
        let app = SmartApp.fromId(".com.example.notRunning")

        #expect(app.name == "未知系统应用")
        #expect(app.isSystemApp)
        #expect(app.hidden)
    }

    @Test("getSystemAppIcon：目录内的系统应用有图标；未知 ID 以「.」开头时回退默认图标，否则无图标")
    func systemAppIconLookup() {
        let known = SmartApp.allSystemApps[0]

        #expect(SmartApp.getSystemAppIcon(known.id) != nil)
        // 未收录但以「.」开头的 ID 会命中 default 分支的默认图标。
        #expect(SmartApp.getSystemAppIcon(".com.example.notInCatalog") != nil)
        // 不以「.」开头的未知 ID 没有图标。
        #expect(SmartApp.getSystemAppIcon("com.example.notInCatalog") == nil)
    }

    @Test("samples 与系统应用目录一致")
    func samplesMirrorSystemCatalog() {
        #expect(SmartApp.samples == SmartApp.allSystemApps)
    }

    @Test("系统应用目录：ID 唯一、全部标记为系统应用；仅 4 个用户可见应用不隐藏")
    func systemCatalogInvariantsExtra() {
        let apps = SmartApp.allSystemApps

        #expect(Set(apps.map(\.id)).count == apps.count)
        #expect(apps.allSatisfy { $0.isSystemApp })

        // 目录里绝大多数条目是后台系统组件（hidden: true）；
        // 只有 4 个面向用户的系统应用显式标为 hidden: false。
        let visible = apps.filter { !$0.hidden }.map(\.id).sorted()
        #expect(visible == [
            ".com.apple.AppStore",
            ".com.apple.Notes",
            ".com.apple.bird",
            ".com.apple.cloudd"
        ])
        #expect(apps.count - visible.count == 23)
    }
}

/// `FirewallDashboardPlugin` 的生命周期测试。
///
/// 插件会向菜单栏贡献状态项与 popover，并向工具栏贡献两个预览瓦片；
/// 停用/停机/注销时按 owner 撤回这些贡献。
///
/// 生命周期走 `kernel.start(plugins:)`：插件声明了
/// `["firewall", "appsettings", "eventstore", "store"]` 四个依赖，
/// Kernel 启动时会校验依赖是否存在，缺失即拒绝启动。
/// `onEnable` / `onDisable` / `onUnregister` 由 Kernel 内部（非 public）驱动，
/// 单测直接调用；这些方法不经过 `kernel.trackContribution`，
/// 因此不存在 `contributionOwnerUnavailable` 归属校验。
@MainActor
@Suite("FirewallDashboardPlugin")
struct FirewallDashboardPluginTests {

    /// 满足 `FirewallProviding` 的最小实现。
    private final class StubFirewall: FirewallProviding {
        let snapshot = FirewallSnapshot(state: .running)
        func refresh() async {}
        func installSystemExtension() async {}
        func installFilter() async throws {}
        func start() async throws {}
        func stop() async throws {}
        func observe() -> AsyncStream<FirewallSnapshot> { AsyncStream { $0.finish() } }
    }

    /// 只提供插件 ID 的占位插件（用于满足 Kernel 的依赖图校验）。
    private final class PlaceholderPlugin: SuperPlugin {
        let id: String
        var order: Int { 1 }
        var dependencies: [String] { [] }
        let metadata: PluginMetadata

        init(id: String) {
            self.id = id
            self.metadata = PluginMetadata(id: id, name: id, version: "1.0", policy: .enabledByDefault)
        }

        func onBoot(kernel: KernelCoreContainer) throws {}
    }

    /// 注册菜单栏与工具栏 Provider 的插件。
    private final class ShellProviderPlugin: SuperPlugin {
        let id = "shell-provider"
        var order: Int { 1 }
        var dependencies: [String] { [] }
        let metadata = PluginMetadata(id: "shell-provider", name: "Shell", version: "1.0", policy: .enabledByDefault)

        func onBoot(kernel: KernelCoreContainer) throws {
            try kernel.registerProvider(MenuBarProviding.self, DefaultMenuBarProviding())
            try kernel.registerProvider(ShellToolbarProviding.self, ShellCenter())
        }
    }

    /// 注册 `FirewallProviding` 的插件（id 与生产插件一致）。
    private final class FirewallProviderPlugin: SuperPlugin {
        let id = "firewall"
        var order: Int { 1 }
        var dependencies: [String] { [] }
        let metadata = PluginMetadata(id: "firewall", name: "Firewall", version: "1.0", policy: .enabledByDefault)

        func onBoot(kernel: KernelCoreContainer) throws {
            try kernel.registerProvider(FirewallProviding.self, StubFirewall())
        }
    }

    /// 启动一个满足依赖图的内核（含防火墙面板插件）。
    private func makeKernel() throws -> (KernelCoreContainer, FirewallDashboardPlugin) {
        let kernel = KernelCoreContainer()
        let plugin = FirewallDashboardPlugin()
        try kernel.start(plugins: [
            PlaceholderPlugin(id: "appsettings"),
            PlaceholderPlugin(id: "eventstore"),
            PlaceholderPlugin(id: "store"),
            FirewallProviderPlugin(),
            ShellProviderPlugin(),
            plugin,
        ])
        return (kernel, plugin)
    }

    @Test("插件元数据描述防火墙面板")
    func metadata() {
        let plugin = FirewallDashboardPlugin()

        #expect(plugin.id == "firewall-dashboard")
        #expect(plugin.order == 60)
        #expect(plugin.dependencies == ["firewall", "appsettings", "eventstore", "store"])
        #expect(plugin.metadata.id == "firewall-dashboard")
        #expect(plugin.metadata.name == "防火墙面板")
        #expect(plugin.metadata.version == "1.0")
    }

    @Test("kernel 启动插件后向菜单栏与工具栏贡献内容")
    func startContributes() throws {
        let (kernel, _) = try makeKernel()
        let menuBar = try #require(kernel.resolveProvider(MenuBarProviding.self))
        let toolbar = try #require(kernel.resolveProvider(ShellToolbarProviding.self))

        #expect(menuBar.contentItems.map(\.id) == ["firewall-dashboard.status"])
        #expect(menuBar.popupItems.map(\.id) == ["firewall-dashboard"])
        #expect(toolbar.leftContributions.map(\.id) == ["switcher"])
        #expect(toolbar.centerContributions.map(\.id) == ["filter"])
    }

    @Test("onEnable 重复贡献时不会产生重复条目")
    func onEnableIsIdempotent() async throws {
        let (kernel, plugin) = try makeKernel()
        let menuBar = try #require(kernel.resolveProvider(MenuBarProviding.self))

        try await plugin.onEnable(kernel: kernel)

        #expect(menuBar.contentItems.count == 1)
        #expect(menuBar.popupItems.count == 1)
    }

    @Test("onDisable 撤回菜单栏与工具栏贡献")
    func onDisableRemovesContributions() async throws {
        let (kernel, plugin) = try makeKernel()
        let menuBar = try #require(kernel.resolveProvider(MenuBarProviding.self))
        let toolbar = try #require(kernel.resolveProvider(ShellToolbarProviding.self))

        try await plugin.onDisable(kernel: kernel)

        #expect(menuBar.contentItems.isEmpty)
        #expect(menuBar.popupItems.isEmpty)
        #expect(toolbar.leftContributions.isEmpty)
        #expect(toolbar.centerContributions.isEmpty)
    }

    @Test("onShutdown 撤回菜单栏与工具栏贡献")
    func onShutdownRemovesContributions() throws {
        let (kernel, plugin) = try makeKernel()
        let menuBar = try #require(kernel.resolveProvider(MenuBarProviding.self))

        try plugin.onShutdown(kernel: kernel)

        #expect(menuBar.contentItems.isEmpty)
        #expect(menuBar.popupItems.isEmpty)
    }

    @Test("onUnregister 撤回菜单栏与工具栏贡献")
    func onUnregisterRemovesContributions() throws {
        let (kernel, plugin) = try makeKernel()
        let menuBar = try #require(kernel.resolveProvider(MenuBarProviding.self))

        try plugin.onUnregister(kernel: kernel)

        #expect(menuBar.contentItems.isEmpty)
        #expect(menuBar.popupItems.isEmpty)
    }
}
