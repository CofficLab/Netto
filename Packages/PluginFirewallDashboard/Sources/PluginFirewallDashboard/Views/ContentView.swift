import LumiUI
import ProviderAppSettings
import ProviderFirewall
import ProviderFirewallEvents
import ProviderViewEnvironment
import SwiftUI

/// 菜单栏弹窗的主体：筛选 + 应用列表。
///
/// 固定 360pt 高度，保证 NSPopover 的内容高度在引导与列表之间切换时不跳动；
/// 内部滚动由列表自己的 `ScrollView` 承担。应用联网日志不在这里展示，
/// 规则开关由行悬停面板提供。
///
/// 数据全部由推送驱动：会话应用集合、规则变更、实时网速、应用启停各自
/// 走订阅，列表只在应用集合/规则变化时重排；网速更新落到行级模型，
/// 不再触发整表重算。
public struct ContentView: View {
    @EnvironmentObject private var ui: UIProvider
    @Environment(\.settingsProvider) private var settingsRepo
    @Environment(\.eventsProvider) private var eventsRepo
    @Environment(\.firewallProvider) private var firewall
    @Environment(\.networkSpeedProvider) private var networkSpeed

    @State private var model = MenuBarAppsModel()
    /// 应用/图标缓存：注入环境供行与悬停面板取图标。
    @State private var catalog = AppCatalog()
    @State private var firewallState: FirewallState?
    /// 运行中过滤器是否仍有扩展心跳（false 时列表不可信，改为提示未生效）。
    @State private var isFilterResponding = true
    /// App 与系统扩展的 IPC 是否已建立（断开时列表与决策都不可信）。
    @State private var isIPCConnected = true

    @MainActor
    public init() {}

    public var body: some View {
        Group {
            if shouldShowGuide {
                GuideView(
                    state: resolvedState,
                    isFilterResponding: isFilterResponding,
                    isIPCConnected: isIPCConnected,
                    showsBackdrop: false
                )
                    .padding(.vertical, 8)
            } else {
                listContent
            }
        }
        // 列表固定高度避免与引导切换时弹窗跳动；引导内容按自然高度完整展示，
        // 不出现滚动条。
        .frame(height: shouldShowGuide ? nil : 360, alignment: .top)
        .environment(\.appCatalog, catalog)
        .task {
            await model.run(
                catalog: catalog,
                settings: settingsRepo,
                events: eventsRepo,
                speeds: networkSpeed
            )
        }
        .task { await observeFirewallState() }
    }

    // MARK: - List

    private var listContent: some View {
        VStack(spacing: 8) {
            filterPicker
                .padding(.horizontal, 12)

            if filteredApps.isEmpty {
                AppListEmptyView(displayType: ui.displayType)
                    .padding(.horizontal, 12)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredApps) { row in
                            appRow(row)
                        }
                    }
                    .padding(.vertical, 2)
                }
                // 抵消宿主根视图的 8pt 水平内边距，让列表与 Lumi 一样通栏，
                // 行内 12pt 缩进保留。
                .padding(.horizontal, -8)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("netpause.apps.list")
        .onDisappear {
            HoverCoordinator.shared.closeAll()
        }
    }

    private func appRow(_ row: MenuBarAppRowModel) -> some View {
        let hoverID = "netpause.app.hover.\(row.id)"

        return HoverDetailContainer(
            id: hoverID,
            detail: {
                MenuBarAppHoverDetailView(
                    row: row,
                    hoverID: hoverID,
                    onRuleChange: {}
                )
            },
            content: {
                MenuBarAppRow(row: row)
            }
        )
    }

    private var filterPicker: some View {
        Picker("", selection: $ui.displayType) {
            Text("All").tag(DisplayType.All).accessibilityIdentifier("netpause.filter.all")
            Text("Allowed").tag(DisplayType.Allowed).accessibilityIdentifier("netpause.filter.allowed")
            Text("Blocked").tag(DisplayType.Rejected).accessibilityIdentifier("netpause.filter.rejected")
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("netpause.dashboard.filter")
        .labelsHidden()
    }

    // MARK: - Data

    private var filteredApps: [MenuBarAppRowModel] {
        model.rows(for: ui.displayType)
    }

    private var shouldShowGuide: Bool {
        if ui.shouldShowUpgradeGuide { return true }
        guard let resolvedState else { return true }
        // 运行中但过滤器没有响应：列表多半是空的（扩展没起来），
        // 不能停留在应用列表误导用户；IPC 断开时列表同样不可信。
        return resolvedState.isNotRunning() || !isFilterResponding || !isIPCConnected
    }

    private var resolvedState: FirewallState? {
        firewallState ?? firewall?.snapshot.state
    }

    private func observeFirewallState() async {
        guard let firewall else { return }
        firewallState = firewall.snapshot.state
        isFilterResponding = firewall.snapshot.isFilterResponding
        isIPCConnected = firewall.snapshot.isIPCConnected
        for await update in firewall.observe() {
            firewallState = update.state
            isFilterResponding = update.isFilterResponding
            isIPCConnected = update.isIPCConnected
        }
    }
}

#Preview("APP") {
    DashboardPreviewHost { ContentView() }
        .frame(width: 360)
        .frame(height: 360)
}
