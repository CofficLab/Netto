import Foundation
import Observation
import ProviderAppSettings
import ProviderFirewall
import ProviderFirewallEvents

/// 菜单栏列表的行级状态。
///
/// 行视图只绑定自己这一份数据：1Hz 的网速更新只失效对应行，
/// 不会重建整个列表；应用名/图标在 `AppCatalog` 失效时才更新。
@MainActor
@Observable
final class MenuBarAppRowModel: Identifiable {
    let id: String
    var app: SmartApp
    var isDenied: Bool
    var speed: AppNetworkSpeed?

    init(app: SmartApp, isDenied: Bool) {
        self.id = app.id
        self.app = app
        self.isDenied = isDenied
    }
}

/// 菜单栏应用列表的推送式数据源。
///
/// 应用集合来自 `FirewallEventsProviding.observeSessionAppIds()`（纯内存增量集），
/// 规则来自 `AppSettingsProviding.observeChanges()`，网速来自
/// `NetworkSpeedProviding.observe()`。列表顺序只在应用集合/规则变化时重排，
/// 网速逐行更新；应用启动/退出由 `AppCatalog` 通知触发名称与图标刷新。
@MainActor
@Observable
final class MenuBarAppsModel {
    private(set) var rows: [MenuBarAppRowModel] = []

    private var sessionIds: Set<String> = []
    private var deniedIds: Set<String> = []
    private var liveIds: Set<String> = []
    private var rowsByID: [String: MenuBarAppRowModel] = [:]
    private var catalog: (any AppResolving)?

    func row(id: String) -> MenuBarAppRowModel? {
        rowsByID[id]
    }

    func rows(for displayType: DisplayType) -> [MenuBarAppRowModel] {
        switch displayType {
        case .All:
            return rows
        case .Allowed:
            return rows.filter { !deniedIds.contains($0.id) }
        case .Rejected:
            return rows.filter { deniedIds.contains($0.id) }
        }
    }

    /// 直接应用一次快照（预览与单元测试使用，不建立订阅）。
    func applySnapshot(
        catalog: any AppResolving,
        sessionIds: [String],
        deniedIds: Set<String>,
        speeds: [AppNetworkSpeed] = []
    ) {
        self.catalog = catalog
        applySessionIds(sessionIds)
        applyDeniedIds(deniedIds)
        applySpeeds(speeds)
    }

    /// 订阅全部数据源，直到调用方任务取消。
    func run(
        catalog: any AppResolving,
        settings: (any AppSettingsProviding)?,
        events: (any FirewallEventsProviding)?,
        speeds: (any NetworkSpeedProviding)?
    ) async {
        self.catalog = catalog
        guard let settings, let events else { return }

        // 先取快照，再订阅增量，避免订阅建立期间的更新丢失。
        applySessionIds(events.sessionAppIds)
        if let denied = try? await settings.deniedApps() {
            applyDeniedIds(Set(denied.map(\.appId)))
        }
        if let speeds {
            applySpeeds(speeds.snapshot)
        }

        async let eventUpdates: Void = observeSession(events)
        async let ruleUpdates: Void = observeRules(settings)
        async let speedUpdates: Void = observeSpeeds(speeds)
        async let catalogUpdates: Void = observeCatalog()
        _ = await (eventUpdates, ruleUpdates, speedUpdates, catalogUpdates)
    }

    // MARK: - 订阅

    private func observeSession(_ events: any FirewallEventsProviding) async {
        for await ids in events.observeSessionAppIds() {
            applySessionIds(ids)
        }
    }

    private func observeRules(_ settings: any AppSettingsProviding) async {
        for await _ in settings.observeChanges() {
            if let denied = try? await settings.deniedApps() {
                applyDeniedIds(Set(denied.map(\.appId)))
            }
        }
    }

    private func observeSpeeds(_ speeds: (any NetworkSpeedProviding)?) async {
        guard let speeds else { return }
        for await snapshot in speeds.observe() {
            applySpeeds(snapshot)
        }
    }

    private func observeCatalog() async {
        guard let catalog else { return }
        for await _ in catalog.observeChanges() {
            rebuildRows()
        }
    }

    // MARK: - 状态应用

    private func applySessionIds(_ ids: [String]) {
        let next = Set(ids)
        guard next != sessionIds else { return }
        sessionIds = next
        rebuildRows()
    }

    private func applyDeniedIds(_ ids: Set<String>) {
        guard ids != deniedIds else { return }
        deniedIds = ids
        rebuildRows()
    }

    private func applySpeeds(_ speeds: [AppNetworkSpeed]) {
        var speedByID: [String: AppNetworkSpeed] = [:]
        speedByID.reserveCapacity(speeds.count)
        for speed in speeds {
            speedByID[speed.appId] = speed
        }

        let nextLive = Set(speedByID.keys)
        if nextLive != liveIds {
            liveIds = nextLive
            // 新出现的实时应用要先建行；已有行的网速在下面逐行更新。
            rebuildRows()
        }

        for row in rows {
            let next = speedByID[row.id]
            if row.speed != next {
                row.speed = next
            }
        }
    }

    private func rebuildRows() {
        guard let catalog else { return }
        let ids = sessionIds.union(deniedIds).union(liveIds)
        var next: [MenuBarAppRowModel] = []
        var nextByID: [String: MenuBarAppRowModel] = [:]
        next.reserveCapacity(ids.count)

        for id in ids {
            let app = catalog.app(for: id)
            guard app.hasId, !app.isSystemApp || !app.hidden else { continue }
            let row: MenuBarAppRowModel
            if let existing = rowsByID[id] {
                if existing.app != app {
                    existing.app = app
                }
                row = existing
            } else {
                row = MenuBarAppRowModel(app: app, isDenied: deniedIds.contains(id))
            }
            let isDenied = deniedIds.contains(id)
            if row.isDenied != isDenied {
                row.isDenied = isDenied
            }
            next.append(row)
            nextByID[id] = row
        }

        next.sort { lhs, rhs in
            let lhsDenied = deniedIds.contains(lhs.id)
            let rhsDenied = deniedIds.contains(rhs.id)
            if lhsDenied != rhsDenied { return lhsDenied }
            return lhs.app.name.localizedStandardCompare(rhs.app.name) == .orderedAscending
        }

        rows = next
        rowsByID = nextByID
    }
}