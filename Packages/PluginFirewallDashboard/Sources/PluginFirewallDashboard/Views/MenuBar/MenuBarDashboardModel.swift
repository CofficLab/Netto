import Foundation
import Observation
import ProviderAppSettings
import ProviderFirewallEvents

/// 菜单栏仪表盘的应用列表数据源。
///
/// 数据来自两条契约：会话开始以来产生过事件的应用 + 当前被禁止的应用；
/// 合并去重后按「被禁止优先、同组按名称」排序。弹窗是常驻视图，
/// 列表在每次弹窗重新成为 key window 与规则变更后刷新。
@MainActor
@Observable
final class MenuBarDashboardModel {
    private(set) var apps: [SmartApp] = []
    private(set) var deniedIds: Set<String> = []

    func load(
        settings: (any AppSettingsProviding)?,
        events: (any FirewallEventsProviding)?,
        since: Date
    ) async {
        guard let settings, let events else { return }

        let eventAppIds = (try? await events.appIdsSince(since)) ?? []
        let denied = (try? await settings.deniedApps().map(\.appId)) ?? []
        let deniedSet = Set(denied)

        let appIds = Set(eventAppIds).union(denied)
        let resolved = appIds.map { SmartApp.fromId($0) }
            .filter { !$0.isSystemApp || !$0.hidden }
            .filter { $0.hasId }

        apps = Self.sorted(resolved, deniedIds: deniedSet)
        deniedIds = deniedSet
    }

    func filteredApps(for displayType: DisplayType) -> [SmartApp] {
        switch displayType {
        case .All:
            return apps
        case .Allowed:
            return apps.filter { !deniedIds.contains($0.id) }
        case .Rejected:
            return apps.filter { deniedIds.contains($0.id) }
        }
    }

    /// 叠加实时有流量的应用：事件尚未落库时，列表仍应与实时网速一致。
    ///
    /// 实时应用只会出现在「全部 / 允许」；「禁止」只展示已拒绝的应用。
    func filteredApps(for displayType: DisplayType, includingLive liveApps: [SmartApp]) -> [SmartApp] {
        Self.merging(
            filteredApps(for: displayType),
            withLive: liveApps,
            displayType: displayType,
            deniedIds: deniedIds
        )
    }

    static func merging(
        _ base: [SmartApp],
        withLive liveApps: [SmartApp],
        displayType: DisplayType,
        deniedIds: Set<String>
    ) -> [SmartApp] {
        guard displayType != .Rejected else { return base }

        var seen = Set(base.map(\.id))
        var merged = base
        for app in liveApps where app.hasId && !seen.contains(app.id) {
            if displayType == .Allowed, deniedIds.contains(app.id) {
                continue
            }
            merged.append(app)
            seen.insert(app.id)
        }
        return sorted(merged, deniedIds: deniedIds)
    }

    /// 被禁止的应用置顶，同组按名称排序；实时应用并入后保持同一顺序。
    private static func sorted(_ apps: [SmartApp], deniedIds: Set<String>) -> [SmartApp] {
        apps.sorted { lhs, rhs in
            let lhsDenied = deniedIds.contains(lhs.id)
            let rhsDenied = deniedIds.contains(rhs.id)
            if lhsDenied != rhsDenied {
                return lhsDenied
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    func isDenied(_ appId: String) -> Bool {
        deniedIds.contains(appId)
    }
}