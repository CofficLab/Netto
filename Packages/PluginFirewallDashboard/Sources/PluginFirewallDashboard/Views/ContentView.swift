import AppKit
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
public struct ContentView: View {
    @EnvironmentObject private var ui: UIProvider
    @Environment(\.settingsProvider) private var settingsRepo
    @Environment(\.eventsProvider) private var eventsRepo
    @Environment(\.firewallProvider) private var firewall
    @Environment(\.networkSpeedProvider) private var networkSpeed
    @Environment(\.sessionStartDate) private var sessionStartDate

    @State private var model = AppListModel()
    @State private var firewallState: FirewallState?
    @State private var speeds: [AppNetworkSpeed] = []
    /// 菜单栏弹窗的呈现会话：弹窗关闭时复位选中的应用。
    @State private var presentationSession = PopoverPresentationSession()

    @MainActor
    public init() {}

    public var body: some View {
        Group {
            if isShowingGuide {
                GuideView(state: resolvedState, showsBackdrop: false)
                    .padding(.vertical, 8)
            } else if let app = selectedApp {
                MenuBarAppDetailView(
                    app: app,
                    onBack: { ui.clearSelectedApp() },
                    onRuleChange: refresh
                )
            } else {
                listContent
            }
        }
        // 升级引导覆盖在当前子视图之上：达到免费版限制时提示必须立刻可见，
        // 不能因为停留在应用详情页而被隐藏。
        .overlay {
            // 升级引导覆盖在当前子视图之上：达到免费版限制时提示必须立刻可见，
            // 不能因为停留在应用详情页而被隐藏。
            UpgradeGuideOverlay(state: resolvedState)
        }
        // 列表与详情固定高度避免切换时弹窗跳动；引导内容按自然高度完整展示，
        // 不出现滚动条。
        .frame(height: isShowingGuide ? nil : 360, alignment: .top)
        .onAppear(perform: refresh)
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
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            refresh()
        }
        .task { await observeFirewallState() }
        .task { await observeNetworkSpeeds() }
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
                        ForEach(filteredApps, id: \.id) { app in
                            appRow(app)
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
        .accessibilityIdentifier("netto.apps.list")
        .onDisappear {
            HoverCoordinator.shared.closeAll()
        }
    }

    private func appRow(_ app: SmartApp) -> some View {
        let hoverID = "netto.app.hover.\(app.id)"
        let isDenied = model.isDenied(app.id)
        let speed = speeds.first { $0.appId == app.id }

        return HoverDetailContainer(
            id: hoverID,
            detail: {
                MenuBarAppHoverDetailView(
                    app: app,
                    isDenied: isDenied,
                    speed: speed,
                    hoverID: hoverID,
                    onRuleChange: refresh
                )
            },
            content: {
                MenuBarAppRow(app: app, isDenied: isDenied, speed: speed)
            }
        )
    }

    private var filterPicker: some View {
        Picker("", selection: $ui.displayType) {
            Text("全部").tag(DisplayType.All).accessibilityIdentifier("netto.filter.all")
            Text("允许").tag(DisplayType.Allowed).accessibilityIdentifier("netto.filter.allowed")
            Text("禁止").tag(DisplayType.Rejected).accessibilityIdentifier("netto.filter.rejected")
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("netto.dashboard.filter")
        .labelsHidden()
    }

    // MARK: - Data

    private var filteredApps: [SmartApp] {
        model.filteredApps(for: ui.displayType, includingLive: visibleSpeedEntries.map(\.app))
    }

    /// 实时应用与应用列表使用同一套可见性规则：隐藏的系统进程不进入榜单。
    private var visibleSpeedEntries: [(speed: AppNetworkSpeed, app: SmartApp)] {
        speeds.compactMap { speed in
            let app = SmartApp.fromId(speed.appId)
            guard app.hasId, !app.isSystemApp || !app.hidden else { return nil }
            return (speed: speed, app: app)
        }
    }

    private var selectedApp: SmartApp? {
        guard let id = ui.selectedAppId else { return nil }
        return model.apps.first { $0.id == id } ?? SmartApp.fromId(id)
    }

    private var isShowingGuide: Bool {
        ui.selectedAppId == nil && shouldShowGuide
    }

    private var shouldShowGuide: Bool {
        (resolvedState?.isNotRunning() ?? true) || ui.shouldShowUpgradeGuide
    }

    private var resolvedState: FirewallState? {
        firewallState ?? firewall?.snapshot.state
    }

    private func refresh() {
        Task {
            await model.load(
                settings: settingsRepo,
                events: eventsRepo,
                since: sessionStartDate
            )
        }
    }

    private func observeFirewallState() async {
        guard let firewall else { return }
        firewallState = firewall.snapshot.state
        for await update in firewall.observe() {
            firewallState = update.state
            if !update.state.isRunning() {
                speeds = []
            }
        }
    }

    private func observeNetworkSpeeds() async {
        guard let networkSpeed else { return }
        speeds = networkSpeed.snapshot
        for await update in networkSpeed.observe() {
            speeds = update
        }
    }
}

#Preview("APP") {
    DashboardPreviewHost { ContentView() }
        .frame(width: 360)
        .frame(height: 360)
}