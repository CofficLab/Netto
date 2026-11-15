import KernelCore
import ProviderAppSettings
import ProviderFirewall
import ProviderMenuBar
import ProviderShell
import SwiftUI

/// 防火墙插件：向菜单栏注入状态图标与紧凑面板，向主窗口提供仪表盘。
@MainActor
public final class FirewallDashboardPlugin: SuperPlugin {
    public let id = "firewall-dashboard"
    public let order = 60
    public let dependencies = ["firewall", "appsettings", "eventstore", "store"]
    public let metadata = PluginMetadata(
        id: "firewall-dashboard",
        name: "防火墙面板",
        description: "向菜单栏注入防火墙状态与面板，向主窗口注入仪表盘",
        version: "1.0",
        policy: .enabledByDefault
    )

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
        kernel.resolveProvider(ShellToolbarProviding.self)?.removeToolbar(ownedBy: id)
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider(ShellToolbarProviding.self)?.removeToolbar(ownedBy: id)
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider(ShellToolbarProviding.self)?.removeToolbar(ownedBy: id)
    }

    private func contribute(to kernel: KernelCoreContainer) throws {
        let menuBar = try kernel.requireProvider(MenuBarProviding.self)
        let firewall = try kernel.requireProvider(FirewallProviding.self)
        let settings = try kernel.requireProvider(AppSettingsProviding.self)
        let toolbar = try kernel.requireProvider(ShellToolbarProviding.self)

        let deniedApps = deniedApps ?? MenuBarDeniedAppsModel(settings: settings)
        self.deniedApps = deniedApps

        try kernel.trackContribution {
            menuBar.removeItems(ownedBy: self.id)
        }
        menuBar.addContent(MenuBarContribution(
            id: "\(id).status",
            title: "防火墙状态",
            order: 60,
            ownerPluginID: id
        ) {
            FirewallMenuBarStatusView(firewall: firewall, deniedApps: deniedApps)
        })
        menuBar.addPopup(MenuBarContribution(
            id: id,
            title: "TravelMode",
            order: 10,
            ownerPluginID: id
        ) {
            FirewallMenuBarPopoverView(firewall: firewall, deniedApps: deniedApps)
        })
        Self.registerPreviewContributions(into: toolbar)
    }

    public static func registerPreviewContributions(into toolbar: ShellToolbarProviding) {
        toolbar.registerToolbar(ToolbarContribution(
            id: "switcher",
            position: .left,
            order: 10,
            ownerPluginID: "firewall-dashboard"
        ) {
            AnyView(TileSwitcher())
        })
        toolbar.registerToolbar(ToolbarContribution(
            id: "filter",
            position: .center,
            order: 20,
            ownerPluginID: "firewall-dashboard"
        ) {
            AnyView(TileFilter())
        })
    }
}
