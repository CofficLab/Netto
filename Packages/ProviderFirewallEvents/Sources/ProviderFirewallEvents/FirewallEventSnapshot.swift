import Foundation

/// 防火墙事件决策。
public enum FirewallEventDecision: String, Sendable, Equatable, Hashable, CaseIterable {
    /// 放行。
    case allowed
    /// 拒绝。
    case rejected

    /// 旧版 `FirewallEvent.Status` 语义：allowed=0、rejected=1（存于
    /// `FirewallEventModel.statusRawValue`）。迁移期由存储插件负责映射。
    public var storageRawValue: Int {
        switch self {
        case .allowed: return 0
        case .rejected: return 1
        }
    }
}

/// 网络流量方向（与 `NETrafficDirection` 解耦的中立值）。
public enum FirewallTrafficDirection: String, Sendable, Equatable, Hashable, CaseIterable {
    case inbound
    case outbound
}

/// 事件变更通知（替代 NotificationCenter 对象传递）。
public enum FirewallEventChange: Sendable, Equatable {
    /// 新事件已创建。
    case created(FirewallEventSnapshot)
    /// 单个事件已删除。
    case deleted(eventID: String)
    /// 全部事件已清空。
    case cleared
}

/// 防火墙事件快照（中立 DTO；SwiftData Model 只留在存储插件）。
public struct FirewallEventSnapshot: Sendable, Equatable, Identifiable {
    /// 稳定 ID（与旧 `FirewallEventDTO.id` 一致，为 appId 或事件唯一标识）。
    public let id: String
    /// 事件时间。
    public let time: Date
    /// 远端地址。
    public let address: String
    /// 端口。
    public let port: String
    /// 来源应用标识符。
    public let sourceAppIdentifier: String
    /// 决策（放行/拒绝）。
    public let status: FirewallEventDecision
    /// 流量方向。
    public let direction: FirewallTrafficDirection
    /// 应用 ID（与 sourceAppIdentifier 一致，保留旧 DTO 字段语义）。
    public let appId: String

    public init(
        id: String,
        time: Date,
        address: String,
        port: String,
        sourceAppIdentifier: String,
        status: FirewallEventDecision,
        direction: FirewallTrafficDirection,
        appId: String
    ) {
        self.id = id
        self.time = time
        self.address = address
        self.port = port
        self.sourceAppIdentifier = sourceAppIdentifier
        self.status = status
        self.direction = direction
        self.appId = appId
    }
}
