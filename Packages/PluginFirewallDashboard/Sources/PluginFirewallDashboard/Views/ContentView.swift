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
    @Environment(\.sessionStartDate) private var sessionStartDate

    @State private var model = MenuBarDashboardModel()
    @State private var firewallState: FirewallState?

    public init() {}

    public var body: some View {
        Group {
            if ui.selectedAppId == nil && shouldShowGuide {
                ScrollView {
                    GuideView(state: resolvedState, showsBackdrop: false)
                        .padding(.vertical, 8)
                }
            } else if let app = selectedApp {
                MenuBarAppDetailView(app: app) {
                    ui.clearSelectedApp()
                }
            } else {
                listContent
            }
        }
        .frame(height: 360, alignment: .top)
        .onAppear(perform: refresh)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            refresh()
        }
        .task { await observeFirewallState() }
    }

    // MARK: - List

    private var listContent: some View {
        VStack(spacing: 8) {
            filterPicker

            if filteredApps.isEmpty {
                AppListEmptyView(displayType: ui.displayType)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredApps, id: \.id) { app in
                            MenuBarAppRow(app: app, isDenied: model.isDenied(app.id)) {
                                refresh()
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("netto.apps.list")
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
        model.filteredApps(for: ui.displayType)
    }

    private var selectedApp: SmartApp? {
        guard let id = ui.selectedAppId else { return nil }
        return model.apps.first { $0.id == id } ?? SmartApp.fromId(id)
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
        }
    }
}

#Preview("APP") {
    DashboardPreviewHost { ContentView() }
        .frame(width: 360)
        .frame(height: 360)
}