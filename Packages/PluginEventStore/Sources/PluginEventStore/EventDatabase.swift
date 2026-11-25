import Foundation
import OSLog
import ProviderFirewallEvents
import ProviderPersistence
import SwiftData

/// 事件库数据层：全部 SwiftData 读写都在 `SerialModelDatabase` 的串行队列上执行。
///
/// 写入采用写后合并：事件先插入 context，累计 1 秒或 200 条后统一 `save()`，
/// 避免每条连接一次 WAL 提交。同一 context 上的分页/计数立即可见未提交事件；
/// 删除、维护与显式 flush 会先提交待写事件。
///
/// 并发边界：actor 隔离待写计数与延迟提交任务；SwiftData 访问本身由
/// `SerialModelDatabase` 的专用队列串行化。
actor EventDatabase {
    private let database: SerialModelDatabase
    private let logger = Logger(
        subsystem: "com.yueyi.TravelMode.PluginEventStore",
        category: "database"
    )

    private let flushDelay: TimeInterval = 1
    private let flushThreshold = 200

    private var pendingInsertCount = 0
    /// 每次插入递增；用于 await 期间并发插入时只扣减已提交部分。
    private var insertGeneration = 0
    private var flushTask: Task<Void, Never>?

    init(container: ModelContainer) {
        self.database = SerialModelDatabase(
            container: container,
            label: "com.yueyi.TravelMode.eventstore.database"
        )
    }

    // MARK: - 写入

    func insert(_ snapshot: FirewallEventSnapshot) async throws {
        try await database.perform { context in
            context.insert(snapshot.toModel())
        }
        pendingInsertCount += 1
        insertGeneration += 1

        if pendingInsertCount >= flushThreshold {
            try await flush()
        } else {
            scheduleFlush()
        }
    }

    /// 立即提交待写事件；shutdown / 维护路径调用。
    func flush() async throws {
        cancelScheduledFlush()
        try await savePending()
    }

    func deleteByAppId(_ appId: String) async throws {
        let pending = pendingInsertCount
        let generation = insertGeneration
        try await database.perform { context in
            if pending > 0 { try context.save() }
            let predicate = #Predicate<FirewallEventModel> { item in
                item.sourceAppIdentifier == appId
            }
            try context.delete(model: FirewallEventModel.self, where: predicate)
            try context.save()
        }
        settleSaved(pending: pending, generation: generation)
    }

    func deleteAll() async throws -> Int {
        let pending = pendingInsertCount
        let generation = insertGeneration
        let count = try await database.perform { context in
            if pending > 0 { try context.save() }
            let count = try context.fetchCount(FetchDescriptor<FirewallEventModel>())
            guard count > 0 else { return 0 }
            try context.delete(model: FirewallEventModel.self, where: nil)
            try context.save()
            return count
        }
        settleSaved(pending: pending, generation: generation)
        return count
    }

    func cleanup(olderThan cutoff: Date) async throws -> Int {
        let pending = pendingInsertCount
        let generation = insertGeneration
        let count = try await database.perform { context in
            if pending > 0 { try context.save() }
            let predicate = #Predicate<FirewallEventModel> { item in
                item.time < cutoff
            }
            let count = try context.fetchCount(FetchDescriptor(predicate: predicate))
            guard count > 0 else { return 0 }
            try context.delete(model: FirewallEventModel.self, where: predicate)
            try context.save()
            return count
        }
        settleSaved(pending: pending, generation: generation)
        return count
    }

    // MARK: - 查询

    func fetchPage(_ query: FirewallEventQuery) async throws -> FirewallEventPage {
        let pending = pendingInsertCount
        let generation = insertGeneration
        let page = try await database.perform { context in
            // SwiftData 的 offset/limit 在“持久化结果 + 内存新增”之间不保证合并顺序，
            // 分页前先提交缓冲，保证页码稳定。
            if pending > 0 { try context.save() }
            let predicate = Self.combinedPredicate(
                appIdentifier: query.appIdentifier,
                status: query.status,
                direction: query.direction
            )
            let totalCount = try context.fetchCount(
                FetchDescriptor<FirewallEventModel>(predicate: predicate)
            )

            var descriptor = FetchDescriptor<FirewallEventModel>(
                predicate: predicate,
                sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
            )
            descriptor.fetchOffset = query.page * query.pageSize
            descriptor.fetchLimit = query.pageSize
            let models = try context.fetch(descriptor)

            return FirewallEventPage(
                events: models.map(\.toSnapshot),
                totalCount: totalCount,
                page: query.page,
                pageSize: query.pageSize
            )
        }
        settleSaved(pending: pending, generation: generation)
        return page
    }

    func count(
        appIdentifier: String?,
        status: FirewallEventDecision?,
        direction: FirewallTrafficDirection?
    ) async throws -> Int {
        try await database.perform { context in
            let predicate = Self.combinedPredicate(
                appIdentifier: appIdentifier,
                status: status,
                direction: direction
            )
            return try context.fetchCount(FetchDescriptor(predicate: predicate))
        }
    }

    func totalCount() async throws -> Int {
        try await database.perform { context in
            try context.fetchCount(FetchDescriptor<FirewallEventModel>())
        }
    }

    /// 时间范围查询（含边界，时间倒序 —— 镜像旧 `EventRepo.fetchByTimeRange`）。
    func fetchByTimeRange(
        from: Date,
        to: Date,
        appIdentifier: String?
    ) async throws -> [FirewallEventSnapshot] {
        try await database.perform { context in
            var predicate = #Predicate<FirewallEventModel> { item in
                item.time >= from && item.time <= to
            }
            if let appIdentifier {
                predicate = #Predicate<FirewallEventModel> { item in
                    item.time >= from && item.time <= to
                        && item.sourceAppIdentifier == appIdentifier
                }
            }
            let descriptor = FetchDescriptor<FirewallEventModel>(
                predicate: predicate,
                sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
            )
            return try context.fetch(descriptor).map(\.toSnapshot)
        }
    }

    func allAppIds() async throws -> [String] {
        try await database.perform { context in
            var descriptor = FetchDescriptor<FirewallEventModel>()
            descriptor.propertiesToFetch = [\.sourceAppIdentifier]
            let models = try context.fetch(descriptor)
            return Array(Set(models.map(\.sourceAppIdentifier))).sorted()
        }
    }

    func appIdsSince(_ date: Date) async throws -> [String] {
        try await database.perform { context in
            let predicate = #Predicate<FirewallEventModel> { item in
                item.time >= date
            }
            var descriptor = FetchDescriptor<FirewallEventModel>(predicate: predicate)
            descriptor.propertiesToFetch = [\.sourceAppIdentifier]
            let models = try context.fetch(descriptor)
            return Array(Set(models.map(\.sourceAppIdentifier))).sorted()
        }
    }

    // MARK: - 待写提交

    private func savePending() async throws {
        let pending = pendingInsertCount
        guard pending > 0 else { return }
        let generation = insertGeneration
        try await database.perform { context in
            try context.save()
        }
        settleSaved(pending: pending, generation: generation)
    }

    /// 只扣减本次已提交的条数；await 期间新插入的计数保留。
    private func settleSaved(pending: Int, generation: Int) {
        guard pending > 0 else { return }
        if insertGeneration == generation {
            pendingInsertCount = 0
        } else {
            pendingInsertCount = max(0, pendingInsertCount - pending)
        }
    }

    private func scheduleFlush() {
        guard flushTask == nil else { return }
        let delay = flushDelay
        flushTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            await self?.scheduledFlushFired()
        }
    }

    private func scheduledFlushFired() async {
        flushTask = nil
        do {
            try await savePending()
        } catch {
            logger.error("事件批量写入失败: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func cancelScheduledFlush() {
        flushTask?.cancel()
        flushTask = nil
    }

    // MARK: - Helpers

    private static func combinedPredicate(
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
}