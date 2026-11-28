import Foundation

/// 防火墙状态快照（不可变值）。
public struct FirewallSnapshot: Sendable, Equatable {
    public let state: FirewallState
    public let canStart: Bool
    public let canStop: Bool
    public let lastUpdated: Date

    /// 过滤器是否在响应（扩展心跳存活）。
    ///
    /// `state == .running` 只代表系统配置里过滤器是启用的；扩展会话可能因
    /// 签名/权限问题没有启动。该字段由扩展的周期上报驱动，运行中长时间
    /// 无上报时置为 false。
    public let isFilterResponding: Bool

    /// App 与系统扩展的 IPC 是否已建立。
    ///
    /// 与 `isFilterResponding` 相互独立：连接断开时既无法判断过滤器是否
    /// 在拦截，扩展侧也会因没有 App 连接而放行流量，界面需要单独提示。
    /// 注意 `isFilterResponding` 此时保持上一次的判定，不代表过滤器未生效。
    public let isIPCConnected: Bool

    public init(
        state: FirewallState,
        canStart: Bool,
        canStop: Bool,
        lastUpdated: Date = Date(),
        isFilterResponding: Bool = true,
        isIPCConnected: Bool = true
    ) {
        self.state = state
        self.canStart = canStart
        self.canStop = canStop
        self.lastUpdated = lastUpdated
        self.isFilterResponding = isFilterResponding
        self.isIPCConnected = isIPCConnected
    }

    /// 便捷构造：由状态推导 canStart/canStop。
    public init(
        state: FirewallState,
        lastUpdated: Date = Date(),
        isFilterResponding: Bool = true,
        isIPCConnected: Bool = true
    ) {
        self.init(
            state: state,
            canStart: state.canStart,
            canStop: state.canStop,
            lastUpdated: lastUpdated,
            isFilterResponding: isFilterResponding,
            isIPCConnected: isIPCConnected
        )
    }
}
