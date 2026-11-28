import LumiUI
import ProviderAppSettings
import ProviderFirewallEvents
import SwiftUI

/// 「数据库」设置详情：事件记录 + 规则列表（DEBUG 调试页）。
///
/// 由 `HostDBPlugin` 在 onBoot 解析 `FirewallEventsProviding` /
/// `AppSettingsProviding` 契约注入（不依赖视图环境），作为设置窗口
/// 「数据库」入口的详情视图；契约缺失时子视图优雅降级（显示空列表）。
///
/// 线程/actor：`View`，数据加载在子视图 `.task` 内异步执行；本视图
/// 无自身副作用。
struct DBDatabaseDetailView: View {
    @LumiTheme private var theme

    private let events: FirewallEventsProviding?
    private let settings: AppSettingsProviding?
    private let eventsDirectory: URL?
    private let settingsDirectory: URL?

    init(
        events: FirewallEventsProviding?,
        settings: AppSettingsProviding?,
        eventsDirectory: URL? = nil,
        settingsDirectory: URL? = nil
    ) {
        self.events = events
        self.settings = settings
        self.eventsDirectory = eventsDirectory
        self.settingsDirectory = settingsDirectory
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppUI.Spacing.sm) {
                Image(systemName: "cylinder.split.1x2")
                    .font(.appBody)
                    .foregroundStyle(theme.primary)
                Text("Database")
                    .font(.appTitle)
                    .foregroundStyle(theme.textPrimary)
            }
            .padding(.horizontal, AppUI.Spacing.md)
            .padding(.top, AppUI.Spacing.md)

            Text("Firewall events and rules stored locally with SwiftData (DEBUG)")
                .font(.appCaption)
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, AppUI.Spacing.md)
                .padding(.top, 2)
                .padding(.bottom, AppUI.Spacing.sm)

            AppSettingsDivider()

            // 不使用外层 ScrollView：`Table` 自带滚动，嵌在 ScrollView 中
            // 拿不到固有高度会被压成 0 高度（列头与行都不渲染）。
            VStack(spacing: 0) {
                DBEventView(events: events, eventsDirectory: eventsDirectory)
                    .frame(maxHeight: .infinity)

                AppSettingsDivider()

                DBSettingView(settings: settings, settingsDirectory: settingsDirectory)
                    .frame(height: 300)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview("Database Details") {
    DBDatabaseDetailView(events: nil, settings: nil)
        .frame(width: 600, height: 500)
}
