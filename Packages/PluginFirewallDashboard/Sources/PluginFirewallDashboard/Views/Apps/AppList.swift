import ProviderViewEnvironment
import OSLog
import ProviderAppSettings
import ProviderFirewall
import ProviderFirewallEvents
import SwiftUI

/**
 * 应用列表视图
 *
 * 显示和管理应用列表，支持根据显示类型过滤应用。
 * 当防火墙未运行或需要升级时显示引导视图。
 * 当列表为空时显示优雅的空视图。
 */
struct AppList: View {
    /// UI状态提供者
    @EnvironmentObject private var ui: UIProvider

    /// 应用设置契约
    @Environment(\.settingsProvider) private var repo: AppSettingsProviding?

    /// 事件存储契约
    @Environment(\.eventsProvider) private var eventRepo: FirewallEventsProviding?

    /// 防火墙契约
    @Environment(\.firewallProvider) private var firewall: FirewallProviding?

    /// 应用列表模型（持有全部应用与被拒绝集合）
    @State private var model = AppListModel()

    /// 应用/图标缓存：注入环境供行视图取图标。
    @State private var catalog = AppCatalog()

    /// 由 `FirewallProviding.observe()` 推送的最新状态；nil 时回落到一次性快照。
    @State private var firewallState: FirewallState?

    /// 过滤后的应用列表
    ///
    /// 根据显示类型（全部/允许/拒绝）和隐藏状态进行过滤。
    var filtedApps: [SmartApp] {
        model.filteredApps(for: ui.displayType).filter { $0.hidden == false }
    }

    /// 日志表情符号
    nonisolated static let emoji = "🖥️"

    /// 构建应用列表视图
    var body: some View {
        ZStack {
            if filtedApps.isEmpty && !shouldShowGuide {
                // 显示空视图：当列表为空且不需要显示引导视图时
                AppListEmptyView(displayType: ui.displayType)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(!filtedApps.isEmpty ? filtedApps : SmartApp.samples, id: \.id) { app in
                            AppLine(app: app)
                        }
                    }
                    .padding(8)
                }
            }

            if shouldShowGuide {
                GuideView(state: resolvedState)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("netto.apps.list")
        .environment(\.appCatalog, catalog)
        .task { await observeFirewallState() }
        .task { await model.run(catalog: catalog, settings: repo, events: eventRepo) }
    }

    /// 是否需要显示引导视图
    ///
    /// 当防火墙未运行或需要升级时显示引导视图。
    private var shouldShowGuide: Bool {
        (resolvedState?.isNotRunning() ?? true) || ui.shouldShowUpgradeGuide
    }

    /// 订阅状态后以推送值为准；订阅前先读一次当前快照，避免首帧闪烁。
    private var resolvedState: FirewallState? {
        firewallState ?? firewall?.snapshot.state
    }
}

// MARK: - Event Handler
extension AppList {
    /// 订阅防火墙状态推送；视图消失时 `.task` 自动取消。
    private func observeFirewallState() async {
        guard let firewall else { return }
        firewallState = firewall.snapshot.state
        for await update in firewall.observe() {
            firewallState = update.state
        }
    }
}

// MARK: - Preview
#Preview("App") {
    ContentView()
        .dashboardPreviewRoot()
        .frame(width: 600, height: 600)
}

#Preview("AppList") {
    AppList()
        .dashboardPreviewRoot()
        .frame(width: 600, height: 800)
}
