import LumiUI
import ProviderAppSettings
import ProviderFirewall
import ProviderFirewallEvents
import ProviderViewEnvironment
import SwiftUI

/// 菜单栏弹窗的主体：筛选 + 应用列表，或单个应用的事件详情。
///
/// 固定 360pt 高度，保证 NSPopover 的内容高度在列表与详情之间切换时不跳动；
/// 内部滚动由各区域自己的 `ScrollView` 承担。
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
    /// 应用/图标缓存：注入环境供行与详情视图取图标。
    @State private var catalog = AppCatalog()
    @State private var firewallState: FirewallState?
    /// 运行中过滤器是否仍有扩展心跳（false 时列表不可信，改为提示未生效）。
    @State private var isFilterResponding = true
    /// 菜单栏弹窗的呈现会话：弹窗关闭时复位选中的应用。
    @State private var presentationSession = PopoverPresentationSession()

    @MainActor
    public init() {}

    public var body: some View {
        Group {
            if isShowingGuide {
                GuideView(
                    state: resolvedState,
                    isFilterResponding: isFilterResponding,
                    showsBackdrop: false
                )
                    .padding(.vertical, 8)
            } else if let app = selectedApp {
                MenuBarAppDetailView(
                    app: app,
                    onBack: { ui.clearSelectedApp() }
                )
            } else {
                listContent
            }
        }
        // 升级引导覆盖在当前子视图之上：达到免费版限制时提示必须立刻可见，
        // 不能因为停留在应用详情页而被隐藏。
        .overlay {
            UpgradeGuideOverlay(state: resolvedState)
        }
        // 列表与详情固定高度避免切换时弹窗跳动；引导内容按自然高度完整展示，
        // 不出现滚动条。
        .frame(height: isShowingGuide ? nil : 360, alignment: .top)
        .onAppear {
            // 选中的应用属于「本次弹窗呈现」：弹窗关闭时复位，
            // 否则下次打开会停在上一次的应用详情。
            let provider = ui
            presentationSession.onEnd = { provider.clearSelectedApp() }
        }
        .background(
            WindowAccessor { window in
                presentationSession.attach(window: window)
            }
        )
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

    private var selectedApp: SmartApp? {
        guard let id = ui.selectedAppId else { return nil }
        return model.row(id: id)?.app ?? catalog.app(for: id)
    }

    private var isShowingGuide: Bool {
        ui.selectedAppId == nil && shouldShowGuide
    }

    private var shouldShowGuide: Bool {
        if ui.shouldShowUpgradeGuide { return true }
        guard let resolvedState else { return true }
        // 运行中但过滤器没有响应：列表多半是空的（扩展没起来），
        // 不能停留在应用列表误导用户。
        return resolvedState.isNotRunning() || !isFilterResponding
    }

    private var resolvedState: FirewallState? {
        firewallState ?? firewall?.snapshot.state
    }

    private func observeFirewallState() async {
        guard let firewall else { return }
        firewallState = firewall.snapshot.state
        isFilterResponding = firewall.snapshot.isFilterResponding
        for await update in firewall.observe() {
            firewallState = update.state
            isFilterResponding = update.isFilterResponding
        }
    }
}

#Preview("APP") {
    DashboardPreviewHost { ContentView() }
        .frame(width: 360)
        .frame(height: 360)
}