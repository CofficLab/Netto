import KernelCore
import LumiFactory
import PluginBrandLogo
import PluginFirewallDashboard
import ProviderLogo
import ProviderMenuBar
import ProviderSettingView
import ProviderShell
import SwiftUI
import XCTest
@testable import TravelMode

/// 共享装配引擎（KernelAssembler）行为守卫：插件顺序 / 失败归因 / 异步生命周期 /
/// 仪表盘贡献生命周期。由 FactoryNettoTests 迁移，改用 HostManifest 自定义清单。
@MainActor
final class NettoAssemblerBehaviorTests: XCTestCase {

    func testMakeKernelStartsPluginsInOrder() async throws {
        let a = MockPlugin(id: "A", order: 20, marker: "a")
        let b = MockPlugin(id: "B", order: 10, marker: "b")
        a.registerProvider = false
        let kernel = try await NettoTestKernel.make(manifest: NettoTestManifest.minimal(plugins: [a, b]))

        XCTAssertEqual(kernel.resolveProvider(MarkerProviding.self)?.marker, "b")
        XCTAssertEqual(kernel.registeredPluginCount, 2)
        XCTAssertEqual(kernel.lifecycleState, .running)
    }

    func testMakeKernelFailurePropagates() async throws {
        let failing = MockPlugin(id: "F", marker: "f")
        failing.bootError = NSError(domain: "test", code: 1)
        do {
            _ = try await NettoTestKernel.make(manifest: NettoTestManifest.minimal(plugins: [failing]))
            XCTFail("期望抛出 pluginLifecycleFailed")
        } catch {
            // KernelCore 把生命周期错误包装成 pluginLifecycleFailed，附带归属信息
            // （插件 ID + 阶段），底层错误保留在 underlying 里。
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
        let kernel = try await NettoTestKernel.make(manifest: NettoTestManifest.minimal(plugins: [asyncPlugin]))

        XCTAssertEqual(kernel.lifecycleState, .running)
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
        let kernel = try await NettoTestKernel.make(
            manifest: NettoTestManifest.dashboard(plugins: dependencies + [dashboard])
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

    /// 插件注入设置入口（复刻 HostSettingsPlugin 注入「通用」入口）：
    /// 注册后设置视图渲染双栏布局，入口可被解析选中。
    func testMakeSettingsViewRendersInjectedEntries() async throws {
        let kernel = try await NettoTestKernel.make(manifest: NettoTestManifest.minimal(plugins: []))
        let settings = try XCTUnwrap(kernel.resolveProvider((any SettingViewProviding).self))
        settings.registerEntries([
            SettingEntryItem(id: "general", title: "通用", systemImage: "gearshape", order: 5) {
                Text("general-panel")
            },
        ])

        XCTAssertEqual(settings.entries.count, 1)
        XCTAssertEqual(settings.selectedEntryID, "general")
        XCTAssertNotNil(settings.makeSettingView())
    }

    /// 菜单栏品牌图标由插件贡献：基线注册 LogoProviding，插件在 onBoot 追加
    /// LogoItem，状态栏取最高优先级项（无贡献时退回 App 资源）。
    func testBrandLogoPluginContributesMenuBarLogo() async throws {
        let kernel = try await NettoTestKernel.make(manifest: NettoTestManifest.minimal(plugins: []))
        let logo = try XCTUnwrap(kernel.resolveProvider((any LogoProviding).self))
        XCTAssertNil(logo.highestPriorityLogoItem, "没有 Logo 插件时不应有贡献")

        try BrandLogoPlugin().onBoot(kernel: kernel)

        XCTAssertEqual(logo.highestPriorityLogoItem?.id, "brand-logo")
    }
}