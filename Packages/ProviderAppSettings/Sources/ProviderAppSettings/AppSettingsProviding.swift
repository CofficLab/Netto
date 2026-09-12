import Foundation

/// 应用允许/阻止规则快照。
public struct AppSettingSnapshot: Sendable, Equatable, Identifiable {
    public let appId: String
    public let allowed: Bool

    public init(appId: String, allowed: Bool) {
        self.appId = appId
        self.allowed = allowed
    }

    public var id: String { appId }
}

/// 设置变更通知（替代 NotificationCenter 的 firewallDidSetAllow/Deny）。
public enum AppSettingsChange: Sendable, Equatable {
    case didAllow(appId: String)
    case didDeny(appId: String)
}

/// 应用设置能力契约。
///
/// 逐项保留旧 `AppSettingRepo` 的规则 CRUD、查询、计数、同步/异步 shouldAllow
/// 与通知行为。SwiftData Model 类型不得出现在本协议中。
///
/// 线程/actor：实现为 `@MainActor` 对象；`shouldAllowSync` 保留给 IPC 回调
/// 同步决策路径（迁移期兼容）。
@MainActor
public protocol AppSettingsProviding: AnyObject, Sendable {
    /// 全部规则。
    func fetchAll() async throws -> [AppSettingSnapshot]

    /// 单条规则；不存在返回 nil。
    func find(_ appId: String) async throws -> AppSettingSnapshot?

    /// 被拒绝访问的应用列表。
    func deniedApps() async throws -> [AppSettingSnapshot]

    /// 被拒绝访问的应用数量（旧 `getDeniedAppsCount` 语义）。
    func deniedAppsCount() async throws -> Int

    /// 是否应允许访问（异步；无规则时默认允许）。
    func shouldAllow(_ appId: String) async -> Bool

    /// 是否应允许访问（同步；IPC 决策路径用）。
    func shouldAllowSync(_ appId: String) -> Bool

    /// 允许访问（写入并通知）。
    func setAllow(_ appId: String) async throws

    /// 拒绝访问（写入并通知）。
    func setDeny(_ appId: String) async throws

    /// 删除规则。
    func delete(_ appId: String) async throws

    /// 观察变更（替代 NotificationCenter）。
    func observeChanges() -> AsyncStream<AppSettingsChange>
}
