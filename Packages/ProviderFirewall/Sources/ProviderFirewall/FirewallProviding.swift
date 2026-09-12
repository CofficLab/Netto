import Foundation

/// 防火墙能力契约。
///
/// 只暴露中立状态 Snapshot 与命令；UI、StoreKit、SwiftData、NE 具体类型
/// 不得出现在本协议中。
///
/// 线程/actor：实现为 `@MainActor` 对象（状态在 MainActor 维护）；
/// 观察者通过 `observe()` 的 AsyncStream 接收快照更新。
@MainActor
public protocol FirewallProviding: AnyObject, Sendable {
    /// 当前状态快照。
    var snapshot: FirewallSnapshot { get }

    /// 刷新状态（系统扩展属性请求 + 过滤器启用状态检查）。
    func refresh() async

    /// 安装系统扩展（激活请求，可能弹出用户审批）。
    func installSystemExtension() async

    /// 安装过滤器配置到系统设置。
    func installFilter() async throws

    /// 启动防火墙（确保扩展激活 + 过滤器安装 + 启用）。
    func start() async throws

    /// 停止防火墙。
    func stop() async throws

    /// 观察状态快照更新（AsyncStream；订阅方负责消费与取消）。
    func observe() -> AsyncStream<FirewallSnapshot>
}
