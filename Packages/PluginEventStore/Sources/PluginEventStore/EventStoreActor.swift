import Foundation
import ProviderPersistence
import ProviderFirewallEvents
import SwiftData

/// 串行执行 SwiftData 查询的 actor（对应旧 `EventQueryActor` 语义）。///
/// 逐项保留旧行为：组合谓词（appId + status + direction）、按时间倒序、
/// 0-based 分页 offset/limit、去重应用 ID、计数口径。
///
/// 线程/actor：`ModelActor`，内部串行访问 modelContext。
actor EventStoreActor: ModelActor {
    let modelContainer: ModelContainer
    nonisolated let modelExecutor: ModelExecutor

    init(container: ModelContainer) {
        self.modelContainer = container
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: ModelContext(container))
    }

    // MARK: - 组合谓词（与旧实现一致：reduce 组合 #Predicate）

    private func combinedPredicate(
        appIdentifier: String?,
        status: FirewallEventDecision?,
        direction: FirewallTrafficDirection?
    ) -> Predicate<FirewallEventModel> {
        var predicates: [Predicate<FirewallEventModel>] = []
        if let appIdentifier {
            predicates.append(#Predicate<FirewallEventModel> { item in
                item.sourceAppIdentifier == appIdentifier
            })
        }
        if let status {
            let raw = status.storageRawValue
            predicates.append(#Predicate<FirewallEventModel> { item in
                item.statusRawValue == raw
            })
        }
        if let direction {
            let raw = direction.storageRawValue
            predicates.append(#Predicate<FirewallEventModel> { item in
                item.directionRawValue == raw
            })
        }

        guard let first = predicates.first else {
            return #Predicate<FirewallEventModel> { _ in true }
        }
        return predicates.dropFirst().reduce(into: first) { result, predicate in
            result = #Predicate<FirewallEventModel> { item in
                result.evaluate(item) && predicate.evaluate(item)
            }
        }
    }

    // MARK: - 分页 / 计数

    func fetchPage(_ query: FirewallEventQuery) throws -> FirewallEventPage {
        let predicate = combinedPredicate(
            appIdentifier: query.appIdentifier,
            status: query.status,
            direction: query.direction
        )
        let countDescriptor = FetchDescriptor<FirewallEventModel>(predicate: predicate)
        let totalCount = try modelContext.fetchCount(countDescriptor)

        var listDescriptor = FetchDescriptor<FirewallEventModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        listDescriptor.fetchOffset = query.page * query.pageSize
        listDescriptor.fetchLimit = query.pageSize

        let models = try modelContext.fetch(listDescriptor)
        return FirewallEventPage(
            events: models.map(\.toSnapshot),
            totalCount: totalCount,
            page: query.page,
            pageSize: query.pageSize
        )
    }

    func count(appIdentifier: String?, status: FirewallEventDecision?, direction: FirewallTrafficDirection?) throws -> Int {
        let predicate = combinedPredicate(appIdentifier: appIdentifier, status: status, direction: direction)
        return try modelContext.fetchCount(FetchDescriptor(predicate: predicate))
    }

    func totalCount() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<FirewallEventModel>())
    }

    // MARK: - CRUD

    func create(_ snapshot: FirewallEventSnapshot) throws {
        modelContext.insert(snapshot.toModel())
        try modelContext.save()
    }

    func deleteByAppId(_ appId: String) throws {
        let predicate = #Predicate<FirewallEventModel> { item in
            item.sourceAppIdentifier == appId
        }
        let events = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        for event in events {
            modelContext.delete(event)
        }
        try modelContext.save()
    }

    func deleteAll() throws -> Int {
        let events = try modelContext.fetch(FetchDescriptor<FirewallEventModel>())
        let count = events.count
        for event in events {
            modelContext.delete(event)
        }
        if count > 0 { try modelContext.save() }
        return count
    }

    func cleanupOlderThan(days: Int) throws -> Int {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<FirewallEventModel> { item in
            item.time < cutoffDate
        }
        let events = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        let count = events.count
        for event in events {
            modelContext.delete(event)
        }
        if count > 0 { try modelContext.save() }
        return count
    }

    // MARK: - 查询

    /// 时间范围查询（含边界，时间倒序 —— 镜像旧 `EventRepo.fetchByTimeRange`）。
    func fetchByTimeRange(from: Date, to: Date, appIdentifier: String?) throws -> [FirewallEventSnapshot] {
        var predicate = #Predicate<FirewallEventModel> { item in
            item.time >= from && item.time <= to
        }
        if let appIdentifier {
            predicate = #Predicate<FirewallEventModel> { item in
                item.time >= from && item.time <= to && item.sourceAppIdentifier == appIdentifier
            }
        }
        let descriptor = FetchDescriptor<FirewallEventModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(\.toSnapshot)
    }

    func allAppIds() throws -> [String] {
        let models = try modelContext.fetch(
            FetchDescriptor<FirewallEventModel>(
                sortBy: [SortDescriptor(\.sourceAppIdentifier, order: .forward)]
            )
        )
        return Array(Set(models.map(\.sourceAppIdentifier))).sorted()
    }

    func appIdsSince(_ date: Date) throws -> [String] {
        let predicate = #Predicate<FirewallEventModel> { item in
            item.time >= date
        }
        let models = try modelContext.fetch(
            FetchDescriptor<FirewallEventModel>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.sourceAppIdentifier, order: .forward)]
            )
        )
        return Array(Set(models.map(\.sourceAppIdentifier))).sorted()
    }

    /// 数据库健康检查：执行一次平凡查询（旧 `performBackgroundTask` 语义）。
    func checkHealth() throws -> Bool {
        _ = try modelContext.fetch(FetchDescriptor<AppSetting>())
        return true
    }
}
