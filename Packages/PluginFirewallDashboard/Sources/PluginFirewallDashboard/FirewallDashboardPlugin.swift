import KernelCore
import ProviderFirewall
import ProviderMenuBar
import ProviderShell
import SwiftUI

/// 防火墙仪表盘插件：将主面板作为菜单栏 popover 内容贡献给 Host。
@MainActor
public final class FirewallDashboardPlugin: SuperPlugin {
    public let id = "firewall-dashboard"
    public let order = 60
    public let dependencies = ["firewall", "appsettings", "eventstore", "store"]
    public let metadata = PluginMetadata(
        name: "防火墙面板",
        version: "1.0",
        policy: .enabledByDefault,
        summary: "向菜单栏 popover 注入防火墙主面板"
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        try contribute(to: kernel)
    }

    public func onEnable(kernel: KernelCoreContainer) async throws {
        try contribute(to: kernel)
    }

    public func onDisable(kernel: KernelCoreContainer) async throws {
        kernel.resolveProvider(MenuBarProviding.self)?.removeItems(ownedBy: id)
        kernel.resolveProvider(ShellToolbarProviding.self)?.removeToolbar(ownedBy: id)
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider(MenuBarProviding.self)?.removeItems(ownedBy: id)
        kernel.resolveProvider(ShellToolbarProviding.self)?.removeToolbar(ownedBy: id)
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider(MenuBarProviding.self)?.removeItems(ownedBy: id)
        kernel.resolveProvider(ShellToolbarProviding.self)?.removeToolbar(ownedBy: id)
    }

    private func contribute(to kernel: KernelCoreContainer) throws {
        let menuBar = try kernel.requireProvider(MenuBarProviding.self)
        let firewall = try kernel.requireProvider(FirewallProviding.self)
        let toolbar = try kernel.requireProvider(ShellToolbarProviding.self)
        let itemID = "firewall-dashboard"
        menuBar.addContent(MenuBarContribution(
            id: "\(id).status",
            title: "防火墙状态",
            order: 60,
            ownerPluginID: id
        ) {
            FirewallMenuBarStatusView(firewall: firewall)
        })
        menuBar.addPopup(MenuBarContribution(
            id: itemID,
            title: "TravelMode",
            order: 10,
            ownerPluginID: id
        ) {
            ContentView()
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

@MainActor
private struct FirewallMenuBarStatusView: View {
    let firewall: any FirewallProviding
    @State private var snapshot: FirewallSnapshot

    init(firewall: any FirewallProviding) {
        self.firewall = firewall
        _snapshot = State(initialValue: firewall.snapshot)
    }

    private var symbol: String {
        switch snapshot.state {
        case .running: "shield.fill"
        case .stopped, .disabled: "shield.slash"
        case .unknown: "shield"
        case .failed: "exclamationmark.shield.fill"
        default: "shield.lefthalf.filled"
        }
    }

    private var color: Color {
        switch snapshot.state {
        case .running: .green
        case .stopped, .disabled, .unknown: .secondary
        case .failed: .red
        default: .orange
        }
    }

    private var statusText: String {
        switch snapshot.state {
        case .running: "防火墙运行中"
        case .stopped, .disabled: "防火墙已停止"
        case .unknown: "防火墙状态未知"
        case .failed: "防火墙发生错误"
        default: "防火墙需要处理"
        }
    }

    var body: some View {
        Image(systemName: symbol)
            .foregroundStyle(color)
            .frame(width: 18, height: 20)
            .accessibilityLabel(statusText)
            .help(statusText)
            .task {
                for await update in firewall.observe() {
                    snapshot = update
                }
            }
    }
}
