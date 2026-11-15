import KernelCore
import ProviderAppSettings
import ProviderFirewall
import ProviderMenuBar
import ProviderShell
import ProviderToolbar
import SwiftUI

/// 防火墙插件：向菜单栏注入状态图标与紧凑面板，向主窗口工具栏提供开关与筛选。
@MainActor
public final class FirewallDashboardPlugin: SuperPlugin {
    public let id = "firewall-dashboard"
    public let order = 60
    public let dependencies = ["firewall", "appsettings", "eventstore", "store"]
    public let metadata = PluginMetadata(
        id: "firewall-dashboard",
        name: "防火墙面板",
        description: "向菜单栏注入防火墙状态与面板，向主窗口工具栏注入开关与筛选",
        version: "1.0",
        policy: .enabledByDefault
    )

    /// 工具栏贡献的稳定 ID（宿主共享工具栏按位置渲染）。
    private static let toolbarItemIDs = ["switcher", "filter"]

    /// 状态图标与面板共享的「被阻止应用」观察者（单消费者流，必须共用）。
    private var deniedApps: MenuBarDeniedAppsModel?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        try contribute(to: kernel)
    }

    public func onEnable(kernel: KernelCoreContainer) async throws {
        try contribute(to: kernel)
    }

    public func onDisable(kernel: KernelCoreContainer) async throws {
        removeContributions(from: kernel)
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        removeContributions(from: kernel)
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        removeContributions(from: kernel)
    }

    private func contribute(to kernel: KernelCoreContainer) throws {
        let menuBar = try kernel.requireProvider(MenuBarProviding.self)
        let firewall = try kernel.requireProvider(FirewallProviding.self)
        let settings = try kernel.requireProvider(AppSettingsProviding.self)

        let deniedApps = deniedApps ?? MenuBarDeniedAppsModel(settings: settings)
        self.deniedApps = deniedApps

        try kernel.trackContribution(ownerPluginID: id) {
            menuBar.removeItems(ownedBy: self.id)
        }
        // 状态栏只保留宿主装配的品牌 Logo：防火墙状态与操作都在 popover 内呈现，
        // 避免菜单栏出现「品牌图标 + 状态图标」两个图标。
        menuBar.addPopup(MenuBarContribution(
            id: id,
            title: "TravelMode",
            order: 10,
            ownerPluginID: id
        ) {
            FirewallMenuBarPopoverView(firewall: firewall, deniedApps: deniedApps)
        })

        // 主窗口工具栏（与 Lumi / Wakey 共用 ProviderToolbar）：
        // 左侧开关、居中的筛选分段控件。工具栏 Provider 缺位时静默跳过，
        // 菜单栏路径不受影响。
        guard let toolbar = kernel.resolveProvider((any ToolbarProviding).self) else { return }
        toolbar.addToolbarItems([
            ProviderToolbar.ToolbarItem(
                id: "switcher",
                title: "防火墙开关",
                placement: .leading,
                category: .global,
                ownerPluginID: id,
                order: 10
            ) {
                TileSwitcher()
            },
            ProviderToolbar.ToolbarItem(
                id: "filter",
                title: "筛选应用",
                placement: .center,
                category: .global,
                ownerPluginID: id,
                order: 20
            ) {
                TileFilter()
            },
        ])
    }

    private func removeContributions(from kernel: KernelCoreContainer) {
        kernel.resolveProvider(MenuBarProviding.self)?.removeItems(ownedBy: id)
        kernel.resolveProvider((any ToolbarProviding).self)?
            .removeToolbarItems(ids: Set(Self.toolbarItemIDs))
    }
}
