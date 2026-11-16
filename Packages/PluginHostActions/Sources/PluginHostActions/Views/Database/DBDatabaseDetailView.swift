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

    init(events: FirewallEventsProviding?, settings: AppSettingsProviding?) {
        self.events = events
        self.settings = settings
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppUI.Spacing.sm) {
                Image(systemName: "cylinder.split.1x2")
                    .font(.appBody)
                    .foregroundStyle(theme.primary)
                Text("数据库")
                    .font(.appTitle)
                    .foregroundStyle(theme.textPrimary)
            }
            .padding(.horizontal, AppUI.Spacing.md)
            .padding(.top, AppUI.Spacing.md)

            Text("本地 SwiftData 存储的防火墙事件与规则（DEBUG 调试）")
                .font(.appCaption)
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, AppUI.Spacing.md)
                .padding(.top, 2)
                .padding(.bottom, AppUI.Spacing.sm)

            AppSettingsDivider()

            ScrollView {
                VStack(spacing: 0) {
                    DBEventView(events: events)
                    AppSettingsDivider()
                    DBSettingView(settings: settings)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview("数据库详情") {
    DBDatabaseDetailView(events: nil, settings: nil)
        .frame(width: 600, height: 500)
}
