import Foundation

/// 事件分页查询条件（值语义，可比较）。
public struct FirewallEventQuery: Sendable, Equatable {
    /// 按来源应用筛选。
    public var appIdentifier: String?
    /// 按决策筛选。
    public var status: FirewallEventDecision?
    /// 按方向筛选。
    public var direction: FirewallTrafficDirection?
    /// 页码（从 0 开始，与旧 Repo 语义一致）。
    public var page: Int
    /// 每页条数。
    public var pageSize: Int

    public init(
        appIdentifier: String? = nil,
        status: FirewallEventDecision? = nil,
        direction: FirewallTrafficDirection? = nil,
        page: Int = 0,
        pageSize: Int = 50
    ) {
        self.appIdentifier = appIdentifier
        self.status = status
        self.direction = direction
        self.page = page
        self.pageSize = pageSize
    }
}

/// 事件分页结果。
public struct FirewallEventPage: Sendable, Equatable {
    public let events: [FirewallEventSnapshot]
    public let totalCount: Int
    public let page: Int
    public let pageSize: Int

    public init(events: [FirewallEventSnapshot], totalCount: Int, page: Int, pageSize: Int) {
        self.events = events
        self.totalCount = totalCount
        self.page = page
        self.pageSize = pageSize
    }

    /// 是否还有下一页。
    public var hasNextPage: Bool {
        (page + 1) * pageSize < totalCount
    }
}

/// 事件统计查询（计数口径与旧 Repo 一致）。
public struct FirewallEventCountQuery: Sendable, Equatable {
    public var appIdentifier: String?
    public var status: FirewallEventDecision?
    public var direction: FirewallTrafficDirection?

    public init(
        appIdentifier: String? = nil,
        status: FirewallEventDecision? = nil,
        direction: FirewallTrafficDirection? = nil
    ) {
        self.appIdentifier = appIdentifier
        self.status = status
        self.direction = direction
    }
}

/// 数据库维护结果（与旧 `DBMaintenanceResult` 语义对应）。
public struct FirewallMaintenanceResult: Sendable, Equatable {
    public var deletedEventCount: Int
    public var isDatabaseHealthy: Bool
    public var executionTime: TimeInterval
    public var isSuccessful: Bool
    public var errorMessage: String?

    public init(
        deletedEventCount: Int = 0,
        isDatabaseHealthy: Bool = false,
        executionTime: TimeInterval = 0,
        isSuccessful: Bool = false,
        errorMessage: String? = nil
    ) {
        self.deletedEventCount = deletedEventCount
        self.isDatabaseHealthy = isDatabaseHealthy
        self.executionTime = executionTime
        self.isSuccessful = isSuccessful
        self.errorMessage = errorMessage
    }
}
