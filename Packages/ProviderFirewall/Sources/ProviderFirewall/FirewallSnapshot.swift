import Foundation

/// 防火墙状态快照（不可变值）。
public struct FirewallSnapshot: Sendable, Equatable {
    public let state: FirewallState
    public let canStart: Bool
    public let canStop: Bool
    public let lastUpdated: Date

    public init(state: FirewallState, canStart: Bool, canStop: Bool, lastUpdated: Date = Date()) {
        self.state = state
        self.canStart = canStart
        self.canStop = canStop
        self.lastUpdated = lastUpdated
    }

    /// 便捷构造：由状态推导 canStart/canStop。
    public init(state: FirewallState, lastUpdated: Date = Date()) {
        self.init(
            state: state,
            canStart: state.canStart,
            canStop: state.canStop,
            lastUpdated: lastUpdated
        )
    }
}
