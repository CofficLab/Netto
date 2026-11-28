import Foundation
import OSLog
import ProviderAppSettings
import ProviderPersistence
import SwiftData

/// 应用设置存储 —— `AppSettingsProviding` 实现。
///
/// 规则是网络过滤热路径的输入（扩展每建立一条连接都会请求一次决策），
/// 因此启动时把全部规则载入内存：`shouldAllow` / `shouldAllowSync` /
/// `deniedApps` / 计数都是纯内存 O(1) 查询，决策路径不创建 `ModelContext`。
/// 写入仍走后台数据库，成功后更新缓存并广播。
///
/// 线程/actor：`@MainActor`（缓存与广播）；SwiftData 由 `AppSettingDatabase`
/// 在专用串行队列上执行。
@MainActor
public final class AppSettingsStore: AppSettingsProviding {
    private let database: AppSettingDatabase
    private let logger = Logger(
        subsystem: "com.yueyi.Netpause.PluginAppSettings",
        category: "store"
    )

    /// appId → allowed；缺失即「无规则，默认允许」。
    private var rules: [String: Bool] = [:]
    private var isPrepared = false
    private var changeContinuations: [UUID: AsyncStream<AppSettingsChange>.Continuation] = [:]

    /// 使用共享容器初始化；启动后由插件调用 `prepare()`。
    public init(container: ModelContainer) {
        self.database = AppSettingDatabase(container: container)
    }

    /// 载入全部规则到内存。插件在 onReady 阶段等待完成后才允许开始决策。
    public func prepare() async throws {
        let snapshots = try await database.fetchAll()
        var next: [String: Bool] = [:]
        next.reserveCapacity(snapshots.count)
        for snapshot in snapshots {
            next[snapshot.appId] = snapshot.allowed
        }
        rules = next
        isPrepared = true
    }

    // MARK: - 查询（纯内存）

    public func fetchAll() async throws -> [AppSettingSnapshot] {
        rules
            .map { AppSettingSnapshot(appId: $0.key, allowed: $0.value) }
            .sorted { $0.appId < $1.appId }
    }

    public func find(_ appId: String) async throws -> AppSettingSnapshot? {
        rules[appId].map { AppSettingSnapshot(appId: appId, allowed: $0) }
    }

    public func deniedApps() async throws -> [AppSettingSnapshot] {
        rules
            .filter { !$0.value }
            .map { AppSettingSnapshot(appId: $0.key, allowed: false) }
            .sorted { $0.appId < $1.appId }
    }

    public func deniedAppsCount() async throws -> Int {
        rules.values.reduce(into: 0) { count, allowed in
            if !allowed { count += 1 }
        }
    }

    public func shouldAllow(_ appId: String) async -> Bool {
        rules[appId] ?? true
    }

    public func shouldAllowSync(_ appId: String) -> Bool {
        guard isPrepared else {
            logger.error("规则缓存尚未载入，决策回落到默认允许")
            return true
        }
        return rules[appId] ?? true
    }

    // MARK: - 写入（后台持久化 + 缓存同步）

    public func setAllow(_ appId: String) async throws {
        try await database.upsert(id: appId, allowed: true)
        rules[appId] = true
        notify(.didAllow(appId: appId))
    }

    public func setDeny(_ appId: String) async throws {
        try await database.upsert(id: appId, allowed: false)
        rules[appId] = false
        notify(.didDeny(appId: appId))
    }

    public func delete(_ appId: String) async throws {
        try await database.delete(id: appId)
        rules[appId] = nil
        // 规则被删除后等价于「允许」，观察者必须同步刷新。
        notify(.didAllow(appId: appId))
    }

    // MARK: - 观察

    public func observeChanges() -> AsyncStream<AppSettingsChange> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(16)) { continuation in
            changeContinuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.changeContinuations[id] = nil
                }
            }
        }
    }

    private func notify(_ change: AppSettingsChange) {
        changeContinuations.values.forEach { $0.yield(change) }
    }
}