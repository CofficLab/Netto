import Foundation
import PluginPersistence
import ProviderAppSettings
import SwiftData

/// 应用设置存储 —— `AppSettingsProviding` 实现。
///
/// 逐项保留旧 `AppSettingRepo` 行为：
/// - CRUD：create/updateAllowedStatus（upsert）/delete/find/fetchAll/fetchDeniedApps。
/// - 计数：`deniedAppsCount()`（与旧 `getDeniedAppsCount` 一致，取 denied 列表数量）。
/// - 决策：`shouldAllow` 异步、`shouldAllowSync` 同步（IPC 路径），无规则默认允许。
/// - 通知：`observeChanges()` 以 AsyncStream 取代 NotificationCenter 的
///   `firewallDidSetAllow` / `firewallDidSetDeny`。
///
/// 线程/actor：`@MainActor`；SwiftData 查询由 `AppSettingActor` 串行执行。
@MainActor
public final class AppSettingsStore: AppSettingsProviding {
    private let actor: AppSettingActor
    private let container: ModelContainer
    private var changeContinuation: AsyncStream<AppSettingsChange>.Continuation?

    /// 使用共享容器初始化。
    public init(container: ModelContainer) {
        self.container = container
        self.actor = AppSettingActor(container: container)
    }

    public func fetchAll() async throws -> [AppSettingSnapshot] {
        try await actor.fetchAll()
    }

    public func find(_ appId: String) async throws -> AppSettingSnapshot? {
        try await actor.find(id: appId)
    }

    public func deniedApps() async throws -> [AppSettingSnapshot] {
        try await actor.fetchDenied()
    }

    public func deniedAppsCount() async throws -> Int {
        try await actor.fetchDenied().count
    }

    public func shouldAllow(_ appId: String) async -> Bool {
        do {
            if let snapshot = try await actor.find(id: appId) {
                return snapshot.allowed
            }
            return true // 默认允许（与旧行为一致）
        } catch {
            return true // 默认允许
        }
    }

    public func shouldAllowSync(_ appId: String) -> Bool {
        do {
            let context = ModelContext(container)
            let predicate = #Predicate<AppSetting> { item in
                item.appId == appId
            }
            let items = try context.fetch(FetchDescriptor(predicate: predicate))
            return items.first?.allowed ?? true
        } catch {
            return true // 默认允许
        }
    }

    public func setAllow(_ appId: String) async throws {
        try await actor.upsert(id: appId, allowed: true)
        changeContinuation?.yield(.didAllow(appId: appId))
    }

    public func setDeny(_ appId: String) async throws {
        try await actor.upsert(id: appId, allowed: false)
        changeContinuation?.yield(.didDeny(appId: appId))
    }

    public func delete(_ appId: String) async throws {
        try await actor.delete(id: appId)
    }

    public func observeChanges() -> AsyncStream<AppSettingsChange> {
        AsyncStream { continuation in
            changeContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.changeContinuation = nil
                }
            }
        }
    }
}
