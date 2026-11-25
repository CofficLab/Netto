import Foundation
import Observation
import ProviderAppSettings
import ProviderFirewallEvents

/// 仪表盘应用列表的数据源（设置窗口内的常驻列表）。
///
/// 数据来自两条契约：会话内产生过事件的应用（纯内存增量集）与当前被禁止的
/// 应用；应用名与图标经 `AppCatalog` 缓存。列表由会话/规则/应用启停推送驱动，
/// 不再依赖「窗口成为 key window」触发全量重载。
@MainActor
@Observable
final class AppListModel {
    private(set) var apps: [SmartApp] = []
    private(set) var deniedIds: Set<String> = []

    /// 解析能力与数据源；`load`/`observeChanges` 入口写入，订阅循环只读。
    private var catalog: (any AppResolving)?
    private var settings: (any AppSettingsProviding)?
    private var events: (any FirewallEventsProviding)?

    /// 拉取一次快照（两者都是内存读取，不触达 SwiftData）。
    func load(
        catalog: any AppResolving,
        settings: (any AppSettingsProviding)?,
        events: (any FirewallEventsProviding)?
    ) async {
        self.catalog = catalog
        self.settings = settings
        self.events = events
        await reload()
    }

    private func reload() async {
        guard let catalog, let settings else { return }

        let eventAppIds = events?.sessionAppIds ?? []
        let denied = (try? await settings.deniedApps().map(\.appId)) ?? []
        let deniedSet = Set(denied)

        let resolved = Set(eventAppIds).union(denied).compactMap { id -> SmartApp? in
            let app = catalog.app(for: id)
            guard app.hasId, !app.isSystemApp || !app.hidden else { return nil }
            return app
        }

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

    /// 被禁止的应用置顶，同组按名称排序。
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

    /// 订阅会话应用、规则变更与应用启停；取消即取消全部订阅。
    func observeChanges(
        catalog: any AppResolving,
        settings: (any AppSettingsProviding)?,
        events: (any FirewallEventsProviding)?
    ) async {
        self.catalog = catalog
        self.settings = settings
        self.events = events
        guard let settings else { return }

        async let ruleUpdates: Void = observeRules(settings)
        async let sessionUpdates: Void = observeSession()
        async let catalogUpdates: Void = observeCatalog()
        _ = await (ruleUpdates, sessionUpdates, catalogUpdates)
    }

    func run(
        catalog: any AppResolving,
        settings: (any AppSettingsProviding)?,
        events: (any FirewallEventsProviding)?
    ) async {
        await load(catalog: catalog, settings: settings, events: events)
        await observeChanges(catalog: catalog, settings: settings, events: events)
    }

    private func observeRules(_ settings: any AppSettingsProviding) async {
        for await _ in settings.observeChanges() {
            await reload()
        }
    }

    private func observeSession() async {
        guard let events else { return }
        for await _ in events.observeSessionAppIds() {
            await reload()
        }
    }

    private func observeCatalog() async {
        guard let catalog else { return }
        for await _ in catalog.observeChanges() {
            await reload()
        }
    }
}