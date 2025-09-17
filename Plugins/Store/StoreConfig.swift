import SwiftUI

public enum SubscriptionTier: Int, Comparable, Sendable {
    case none = 0
    case pro = 1
    case ultimate = 2

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    public var isFreeVersion: Bool {
        self == .none
    }

    public var isProOrHigher: Bool {
        self >= .pro
    }

    public var isUltimateOrHigher: Bool {
        self >= .ultimate
    }
}

enum StoreConfig: Sendable {
    // 维护产品ID -> 订阅等级 的映射
    static let productTier: [String: SubscriptionTier] = [
        // Consumables
        "consumable.fuel.octane87": .none,
        "consumable.fuel.octane89": .none,
        "consumable.fuel.octane91": .none,
        
        // Non-consumables
        "nonconsumable.car": .none,
        "nonconsumable.utilityvehicle": .none,
        "nonconsumable.racecar": .none,

        // subscription
        "com.yueyi.netto.pro.monthly": .pro,
        "com.yueyi.netto.pro.annual": .pro,
        "com.yueyi.netto.ultimate.monthly": .ultimate,
        "com.yueyi.netto.ultimate.annual": .ultimate,
    ]

    // 全部商品ID列表（用于请求产品）
    static var allProductIds: [String] {
        Array(productTier.keys)
    }

    // 查询某个产品ID对应的订阅等级
    static func tier(for productId: String) -> SubscriptionTier {
        productTier[productId] ?? .none
    }
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(height: 600)
}
