import Foundation

/// 订阅等级（与旧 `SubscriptionTier` 对应：none/pro/ultimate）。
public enum StoreTier: Int, Sendable, Equatable, Hashable, Comparable {
    case none = 0
    case pro = 1
    case ultimate = 2

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var isFree: Bool { self == .none }
    public var isProOrHigher: Bool { self >= .pro }
    public var isUltimateOrHigher: Bool { self >= .ultimate }
}

/// 当前权益快照（旧 `PurchaseInfo` 语义）。
public struct StoreEntitlementSnapshot: Sendable, Equatable {
    public let tier: StoreTier
    public let expiresAt: Date?

    public init(tier: StoreTier, expiresAt: Date?) {
        self.tier = tier
        self.expiresAt = expiresAt
    }

    /// 未过期且 pro 及以上。
    public var isProOrHigher: Bool {
        guard tier >= .pro else { return false }
        return !isExpired
    }

    /// 是否已过期（与旧实现一致：expiresAt 为 nil 视为过期；不足 60 秒视为未过期）。
    public var isExpired: Bool {
        guard let expiresAt else { return true }
        return expiresAt.distance(to: Date()) > 60
    }

    /// 生效等级：未过期才按 tier，否则 none。
    public var effectiveTier: StoreTier {
        isProOrHigher ? tier : .none
    }

    public static let none = StoreEntitlementSnapshot(tier: .none, expiresAt: nil)
}

/// 产品快照（不暴露 StoreKit.Product）。
public struct StoreProductSnapshot: Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let price: String
    public let tier: StoreTier
    public let isSubscription: Bool

    public init(id: String, displayName: String, price: String, tier: StoreTier, isSubscription: Bool) {
        self.id = id
        self.displayName = displayName
        self.price = price
        self.tier = tier
        self.isSubscription = isSubscription
    }
}

/// StoreKit 能力契约。
///
/// 线程/actor：实现为 `@MainActor` 对象；内部持有交易监听与权益校准，
/// 视图只消费 Snapshot/命令。
@MainActor
public protocol StoreProviding: AnyObject, Sendable {
    /// 当前权益快照。
    var entitlement: StoreEntitlementSnapshot { get }

    /// 加载全部产品。
    func loadProducts() async throws -> [StoreProductSnapshot]

    /// 发起购买。
    func purchase(_ productID: String) async throws

    /// 恢复购买。
    func restore() async throws

    /// 观察权益变化（替代 StoreState 通知）。
    func observeEntitlement() -> AsyncStream<StoreEntitlementSnapshot>
}
