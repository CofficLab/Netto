import Foundation
import ProviderPersistence
import ProviderFirewallEvents
import SwiftData

/// 事件存储 —— `FirewallEventsProviding` 实现。
///
/// 逐项保留旧 `EventRepo` 行为：分页（0-based offset/limit）、组合筛选、
/// 计数、按应用删除、清空、按天数清理、维护触发与事件观察。
/// 旧 NotificationCenter 事件以 `observeChanges()` AsyncStream 取代。
///
/// 线程/actor：`@MainActor`；SwiftData 由 `EventStoreActor` 串行执行。
@MainActor
public final class EventStore: FirewallEventsProviding {
    private let actor: EventStoreActor
    private let maintenanceManager: MaintenanceManager
    private var changeContinuation: AsyncStream<FirewallEventChange>.Continuation?

    /// 本次应用会话起始时间（旧 `sessionStartDate` 语义）。
    public let sessionStartDate: Date

    /// 使用共享容器初始化；启动后由插件调用 `startMaintenance()`。
    public init(container: ModelContainer) {
        self.actor = EventStoreActor(container: container)
        self.maintenanceManager = MaintenanceManager(store: nil)
        self.sessionStartDate = Date()
        self.maintenanceManager.store = self
    }

    // MARK: - 查询

    public func fetchPage(_ query: FirewallEventQuery) async throws -> FirewallEventPage {
        try await actor.fetchPage(query)
    }

    public func count(_ query: FirewallEventCountQuery) async throws -> Int {
        try await actor.count(
            appIdentifier: query.appIdentifier,
            status: query.status,
            direction: query.direction
        )
    }

    public func totalCount() async throws -> Int {
        try await actor.totalCount()
    }

    public func allAppIds() async throws -> [String] {
        try await actor.allAppIds()
    }

    public func fetchByTimeRange(from: Date, to: Date, appIdentifier: String?) async throws -> [FirewallEventSnapshot] {
        try await actor.fetchByTimeRange(from: from, to: to, appIdentifier: appIdentifier)
    }

    public func appIdsSince(_ date: Date) async throws -> [String] {
        try await actor.appIdsSince(date)
    }

    // MARK: - 写操作（变更事件在 MainActor 上同步发出）

    public func create(_ event: FirewallEventSnapshot) async throws {
        try await actor.create(event)
        changeContinuation?.yield(.created(event))
    }

    public func deleteByAppId(_ appId: String) async throws {
        try await actor.deleteByAppId(appId)
        changeContinuation?.yield(.cleared)
    }

    public func deleteAll() async throws -> Int {
        let count = try await actor.deleteAll()
        changeContinuation?.yield(.cleared)
        return count
    }

    public func cleanupOlderThan(days: Int) async throws -> Int {
        try await actor.cleanupOlderThan(days: days)
    }

    public func triggerMaintenance() async throws -> FirewallMaintenanceResult {
        try await maintenanceManager.performMaintenance()
    }

    public func observeChanges() -> AsyncStream<FirewallEventChange> {
        AsyncStream { continuation in
            changeContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.changeContinuation = nil
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
}
