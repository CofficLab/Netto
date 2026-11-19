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
            .sorted { lhs, rhs in
                let lhsDenied = deniedSet.contains(lhs.id)
                let rhsDenied = deniedSet.contains(rhs.id)
                if lhsDenied != rhsDenied {
                    return lhsDenied
                }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }

        apps = resolved
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

    func isDenied(_ appId: String) -> Bool {
        deniedIds.contains(appId)
    }
}