import Foundation

/// 防火墙事件存储能力契约。
///
/// 逐项保留旧 `EventRepo` 的分页、筛选、统计、删除、维护与观察行为，
/// 但只暴露中立 Snapshot/Query。SwiftData `ModelContext`/Model 类型不得出现在本协议中。
///
/// 线程/actor：实现为 `@MainActor` 对象；内部可持有串行查询 actor。
@MainActor
public protocol FirewallEventsProviding: AnyObject, Sendable {
    /// 分页查询事件（appId + 状态 + 方向组合筛选）。
    func fetchPage(_ query: FirewallEventQuery) async throws -> FirewallEventPage

    /// 统计事件数量（组合筛选口径）。
    func count(_ query: FirewallEventCountQuery) async throws -> Int

    /// 事件总数（无筛选）。
    func totalCount() async throws -> Int

    /// 全部去重应用 ID（升序）。
    func allAppIds() async throws -> [String]

    /// 按时间范围查询事件（时间倒序，与旧 `EventRepo.fetchByTimeRange` 语义一致）。
    /// - Parameters:
    ///   - from: 起始时间（含）。
    ///   - to: 结束时间（含）。
    ///   - appIdentifier: 应用筛选；nil 表示不过滤。
    func fetchByTimeRange(from: Date, to: Date, appIdentifier: String?) async throws -> [FirewallEventSnapshot]

    /// 自指定时间起产生事件的应用 ID（去重升序）。
    func appIdsSince(_ date: Date) async throws -> [String]

    /// 本次会话中出现过事件的应用 ID（去重升序）。
    ///
    /// 纯内存读取，不触库；实现应在写入/删除事件时增量维护该集合，
    /// 不得为了得到它而扫描历史事件。
    var sessionAppIds: [String] { get }

    /// 观察会话应用集合变化（订阅时立即推送当前快照）。
    func observeSessionAppIds() -> AsyncStream<[String]>

    /// 创建事件（旧 `createFromDTO` 语义）。
    func create(_ event: FirewallEventSnapshot) async throws

    /// 删除指定应用的全部事件。
    func deleteByAppId(_ appId: String) async throws

    /// 清空全部事件，返回删除数量。
    func deleteAll() async throws -> Int

    /// 清理超过指定天数的事件，返回删除数量。
    func cleanupOlderThan(days: Int) async throws -> Int

    /// 手动触发数据库维护（清理 + 健康检查）。
    func triggerMaintenance() async throws -> FirewallMaintenanceResult

    /// 观察事件变更（替代 NotificationCenter 事件）。
    func observeChanges() -> AsyncStream<FirewallEventChange>
}

public extension FirewallEventsProviding {
    // Mock / 预览实现无需维护会话集合；真实实现必须覆盖这两个成员。
    var sessionAppIds: [String] { [] }

    func observeSessionAppIds() -> AsyncStream<[String]> {
        AsyncStream { $0.finish() }
    }
}
