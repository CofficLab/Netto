import KernelCore
import LumiFactory
import PluginBrandLogo
import ProviderLogo
import ProviderMenuBar
import ProviderPluginManaging
import ProviderRootView
import ProviderSettingView
import ProviderShell
import ProviderToolbar
import SwiftUI
import XCTest
@testable import TravelMode

/// 共享装配引擎解释 TravelMode 清单后的内核基线守卫（hosted 单测）。
///
/// 由 FactoryNettoTests 迁移而来：装配流水线 / 窗口壳 / 状态栏宿主已下沉到
/// 共享包 LumiFactory，这里只守卫 TravelMode 清单的差异接线与生产插件目录。
@MainActor
final class NettoKernelAssemblyTests: XCTestCase {

    /// 清单装配的内核：Shell 五契约 + 共享基线 Provider 就位（无主窗口接线）。
    func testManifestAssemblesKernel() async throws {
        let kernel = try await NettoTestKernel.make()

        XCTAssertEqual(kernel.lifecycleState, .running)
        XCTAssertNotNil(kernel.resolveProvider(ShellToolbarProviding.self))
        XCTAssertNotNil(kernel.resolveProvider(SettingsProviding.self))
        XCTAssertNotNil(kernel.resolveProvider(WindowProviding.self))
        XCTAssertNotNil(kernel.resolveProvider(WindowRoutingProviding.self))
        XCTAssertNotNil(kernel.resolveProvider(ProviderShell.ToastProviding.self))
        XCTAssertNotNil(kernel.resolveProvider(MenuBarProviding.self))
        // 根视图是 host provider（基线 FactoryRootViewProviding），不再经 RootViewPlugin 注册。
        XCTAssertFalse(kernel.isPluginRegistered(id: "com.yueyi.TravelMode.plugin.root-view"))

        let settings = try XCTUnwrap(kernel.resolveProvider((any SettingViewProviding).self))
        XCTAssertNotNil(settings.makeSettingView())
    }

    func testManifestRegistersPluginManagingProvider() async throws {
        let kernel = try await NettoTestKernel.make()
        XCTAssertNotNil(kernel.resolveProvider((any PluginManaging).self))
    }

    /// 纯菜单栏形态：没有主窗口，因此不向共享工具栏贡献任何按钮。
    ///
    /// 基线根视图 Provider 仍由装配引擎注册（无主窗口场景展示它），
    /// 但不承载任何插件内容。
    func testMenuBarOnlyBuildContributesNoToolbarItems() async throws {
        let kernel = try await NettoTestKernel.make()
        let toolbar = try XCTUnwrap(kernel.resolveProvider((any ToolbarProviding).self))

        XCTAssertTrue(toolbar.visibleToolbarItems.isEmpty)
    }

    /// 生产插件目录启动后，菜单栏品牌 Logo 由 `brand-logo` 插件提供。
    func testBrandLogoContributesMenuBarLogo() async throws {
        let kernel = try await NettoTestKernel.make()
        let logo = try XCTUnwrap(kernel.resolveProvider((any LogoProviding).self))
        XCTAssertEqual(logo.highestPriorityLogoItem?.id, "brand-logo")
    }

    /// 纯菜单栏形态：清单不提供主视图钩子，启动/激活都不会打开主窗口。
    func testManifestDoesNotProvideMainWindowHook() {
        let manifest = NettoManifest.manifest

        XCTAssertNil(manifest.makeMainView)
        XCTAssertFalse(manifest.features.opensMainWindowOnLaunch)
        XCTAssertFalse(manifest.features.reopensMainWindowOnActivate)
    }

    /// 状态栏弹窗是唯一主界面：菜单只剩「设置 / 退出」，宽度足以容纳列表。
    func testStatusBarMenuItemsExcludeMainWindowEntry() throws {
        let configuration = try XCTUnwrap(NettoManifest.manifest.features.statusBar)

        XCTAssertEqual(configuration.popoverWidth, 360)
        XCTAssertEqual(
            configuration.menuItems?.compactMap(\.accessibilityIdentifier),
            ["netto.menubar.settings", "netto.menubar.quit"]
        )
    }

    func testMakeSettingsViewUsesResolvedSettings() async throws {
        let kernel = try await NettoTestKernel.make()
        let settings = try XCTUnwrap(kernel.resolveProvider((any SettingViewProviding).self))
        XCTAssertNotNil(settings.makeSettingView())
    }

    /// ShellCenter 工具栏贡献登记（插件按钮经此进入共享工具栏）。
    func testMakeMainViewRendersToolbarContributions() throws {
        let shell = ShellCenter()
        shell.registerToolbar(
            ToolbarContribution(id: "btn", position: .left, order: 10, ownerPluginID: "Test") {
                AnyView(Text("hello"))
            }
        )
        XCTAssertEqual(shell.leftContributions.count, 1)
    }

    /// 宿主窗口路由：wireKernel 把 ShellCenter 的设置请求翻译成标准「打开设置」
    /// 通知并携带深链 entryID（取代旧 SettingsWindowRouter 的深链语义）。
    func testShellRoutingPostsSettingsNotificationWithEntryID() async throws {
        let kernel = try await NettoTestKernel.make()
        let shell = try XCTUnwrap(kernel.resolveProvider(ShellToolbarProviding.self) as? ShellCenter)

        let expectation = expectation(
            forNotification: SettingViewNavigation.openSettingsNotification,
            object: nil
        ) { notification in
            notification.userInfo?[SettingViewNavigation.entryIDUserInfoKey] as? String == "database"
        }
        shell.openSettings(entryID: "database")
        await fulfillment(of: [expectation], timeout: 1)
    }

    /// 显式插件目录含品牌 Logo，且不再挂载 RootViewPlugin（根视图由 host provider 提供）。
    func testPluginAssemblyIncludesBrandLogoWithoutRootViewPlugin() {
        let ids = NettoManifest.makePlugins().map(\.id)

        XCTAssertTrue(ids.contains("brand-logo"), "装配应包含品牌 Logo 插件：\(ids)")
        XCTAssertFalse(
            ids.contains("com.yueyi.TravelMode.plugin.root-view"),
            "根视图由 host provider 提供，不应再挂载 RootViewPlugin：\(ids)"
        )
    }

    /// 设置窗口默认选中规则（回归测试）：全新启动后应选中 order 最小的入口。
    ///
    /// 背景：`addEntries` 走 `registerEntries`，其「选中为空则锁定为当时列表第一个」
    /// 的语义会让最先注册入口的插件意外成为默认选中（兄弟 App 均已踩坑并在内核
    /// 启动后重置），本测试验证 TravelMode。
    func testSettingsDefaultsToFirstEntryByOrder() async throws {
        let kernel = try await NettoTestKernel.make()
        let settings = try XCTUnwrap(kernel.resolveProvider((any SettingViewProviding).self))

        XCTAssertFalse(settings.entries.isEmpty, "设置入口应在内核启动后完成注册")
        let orders = settings.entries.map(\.order)
        XCTAssertEqual(orders, orders.sorted(), "entries must be sorted by order ascending")
        XCTAssertEqual(
            settings.selectedEntryID, settings.entries.first?.id,
            "默认应选中 \(settings.entries.first?.id ?? "nil")，实际为 \(settings.selectedEntryID ?? "nil")"
        )
    }
}