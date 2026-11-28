import KernelCore
import ProviderAppSettings
import ProviderFirewall
import ProviderMenuBar
import ProviderShell
import SwiftUI

/// 防火墙插件：向菜单栏弹窗注入完整仪表盘（状态、启停、筛选、应用列表与事件详情）。
@MainActor
public final class FirewallDashboardPlugin: SuperPlugin {
    public let id = "firewall-dashboard"
    public let order = 60
    public let dependencies = ["firewall", "appsettings", "eventstore", "store"]
    public let metadata = PluginMetadata(
        id: "firewall-dashboard",
        name: String(localized: "Firewall Dashboard"),
        description: String(localized: "Adds firewall status, app lists, and event details to the menu bar popover"),
        version: "1.0",
        policy: .enabledByDefault
    )

    /// 面板共享的「被阻止应用」观察者（单消费者流，必须共用）。
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
        // 状态栏只保留宿主装配的品牌 Logo：防火墙状态与全部操作都在 popover 内呈现，
        // 避免菜单栏出现「品牌图标 + 状态图标」两个图标。
        menuBar.addPopup(MenuBarContribution(
            id: id,
            title: "Netpause",
            order: 10,
            ownerPluginID: id
        ) {
            FirewallMenuBarPopoverView(firewall: firewall, deniedApps: deniedApps)
        })
    }

    private func removeContributions(from kernel: KernelCoreContainer) {
        kernel.resolveProvider(MenuBarProviding.self)?.removeItems(ownedBy: id)
    }
}
