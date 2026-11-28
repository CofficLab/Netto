import Foundation
import OSLog
import ProviderPersistence
import ProviderFirewallEvents
import SwiftData

/// 事件存储 —— `FirewallEventsProviding` 实现。
///
/// 分页/筛选/统计/删除/维护仍按旧 `EventRepo` 语义实现，但：
/// - SwiftData 读写全部在 `EventDatabase` 的专用串行队列上执行，主线程不触库；
/// - 会话应用集合在写入/删除/清理时**增量维护**，读取为纯内存操作，
///   不再为刷新列表扫描历史事件；
/// - 变更流与会话流都支持多订阅者。
///
/// 线程/actor：`@MainActor`（只维护内存状态与广播）。
@MainActor
public final class EventStore: FirewallEventsProviding {
    private let database: EventDatabase
    private let maintenanceManager: MaintenanceManager
    private let logger = Logger(
        subsystem: "com.yueyi.Netpause.PluginEventStore",
        category: "store"
    )

    /// 本次会话中出现过事件的应用 → 最近一条事件时间。
    private var sessionLastEventTime: [String: Date] = [:]
    private var changeContinuations: [UUID: AsyncStream<FirewallEventChange>.Continuation] = [:]
    private var sessionContinuations: [UUID: AsyncStream<[String]>.Continuation] = [:]

    /// 使用共享容器初始化；启动后由插件调用 `startMaintenance()`。
    public init(container: ModelContainer) {
        self.database = EventDatabase(container: container)
        self.maintenanceManager = MaintenanceManager(store: nil)
        self.maintenanceManager.store = self
    }

    // MARK: - 会话应用集合（纯内存）

    public var sessionAppIds: [String] {
        sessionLastEventTime.keys.sorted()
    }

    public func observeSessionAppIds() -> AsyncStream<[String]> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            sessionContinuations[id] = continuation
            continuation.yield(sessionAppIds)
            continuation.onTermination = { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.sessionContinuations[id] = nil
                }
            }
        }
    }

    // MARK: - 查询

    public func fetchPage(_ query: FirewallEventQuery) async throws -> FirewallEventPage {
        try await database.fetchPage(query)
    }

    public func count(_ query: FirewallEventCountQuery) async throws -> Int {
        try await database.count(
            appIdentifier: query.appIdentifier,
            status: query.status,
            direction: query.direction
        )
    }

    public func totalCount() async throws -> Int {
        try await database.totalCount()
    }

    public func allAppIds() async throws -> [String] {
        try await database.allAppIds()
    }

    public func fetchByTimeRange(from: Date, to: Date, appIdentifier: String?) async throws -> [FirewallEventSnapshot] {
        try await database.fetchByTimeRange(from: from, to: to, appIdentifier: appIdentifier)
    }

    public func appIdsSince(_ date: Date) async throws -> [String] {
        try await database.appIdsSince(date)
    }

    // MARK: - 写操作

    public func create(_ event: FirewallEventSnapshot) async throws {
        try await database.insert(event)
        recordSessionEvent(appId: event.sourceAppIdentifier, at: event.time)
        broadcastChange(.created(event))
    }

    public func deleteByAppId(_ appId: String) async throws {
        try await database.deleteByAppId(appId)
        if sessionLastEventTime.removeValue(forKey: appId) != nil {
            broadcastSessionApps()
        }
        broadcastChange(.appCleared(appId: appId))
    }

    public func deleteAll() async throws -> Int {
        let count = try await database.deleteAll()
        if !sessionLastEventTime.isEmpty {
            sessionLastEventTime.removeAll()
            broadcastSessionApps()
        }
        broadcastChange(.cleared)
        return count
    }

    public func cleanupOlderThan(days: Int) async throws -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let deleted = try await database.cleanup(olderThan: cutoff)
        pruneSessionApps(olderThan: cutoff)
        return deleted
    }

    public func triggerMaintenance() async throws -> FirewallMaintenanceResult {
        try await maintenanceManager.performMaintenance()
    }

    /// 立即提交缓冲区中的事件（shutdown 路径）。
    public func flush() async throws {
        try await database.flush()
    }

    public func observeChanges() -> AsyncStream<FirewallEventChange> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(64)) { continuation in
            changeContinuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.changeContinuations[id] = nil
                }
            }
        }
    }

    // MARK: - 维护生命周期

    /// 启动定期维护（每小时清理 + 一次初始维护）。
    public func startMaintenance() {
        maintenanceManager.startPeriodicCleanup()
        maintenanceManager.runInitialMaintenance()
    }

    /// 停止定期维护并取消在途任务。
    public func stopMaintenance() {
        maintenanceManager.stopPeriodicCleanup()
    }

    // MARK: - 会话集合维护

    private func recordSessionEvent(appId: String, at time: Date) {
        guard !appId.isEmpty else { return }
        if let latest = sessionLastEventTime[appId], latest >= time {
            return
        }
        let isNew = sessionLastEventTime[appId] == nil
        sessionLastEventTime[appId] = time
        if isNew {
            broadcastSessionApps()
        }
    }

    private func pruneSessionApps(olderThan cutoff: Date) {
        let survivors = sessionLastEventTime.filter { $0.value >= cutoff }
        guard survivors.count != sessionLastEventTime.count else { return }
        sessionLastEventTime = survivors
        broadcastSessionApps()
    }

    private func broadcastSessionApps() {
        let snapshot = sessionAppIds
        sessionContinuations.values.forEach { $0.yield(snapshot) }
    }

    private func broadcastChange(_ change: FirewallEventChange) {
        changeContinuations.values.forEach { $0.yield(change) }
    }
}