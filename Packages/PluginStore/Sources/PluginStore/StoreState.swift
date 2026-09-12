import Foundation
import MagicCore
import OSLog
import StoreKit

final class StoreState: ObservableObject, SuperLog {
    nonisolated static let emoji = "💰"

    // MARK: - Keys

    private enum Keys {
        static let purchase = "store.purchase"
        static let lastCheckedAt = "store.lastCheckedAt"
    }

    // MARK: - Public API
    
    static func cachedPurchaseInfo() -> PurchaseInfo {
        // 直接从 UserDefaults 取持久化结构
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: Keys.purchase),
           let e = try? JSONDecoder().decode(PurchaseInfo.self, from: data) {
            return e
        }
        return .none
    }

    static func update(entitlement: PurchaseInfo) {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(entitlement) {
            defaults.set(data, forKey: Keys.purchase)
        }
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.lastCheckedAt)
        os_log("\(self.t)🍋 Updated tier=\(entitlement.tier.rawValue), expiresAt=\(entitlement.expiresAtString)")
        // 模块内权益变更桥：PluginStore.observeEntitlement() 消费。
        NotificationCenter.default.post(name: .storeEntitlementUpdated, object: nil)
    }

    static func clear() {
        update(entitlement: .none)
    }

    // 校准：从当前权益拉取并写入本地状态
    static func calibrateFromCurrentEntitlements() async {
        var detectedTier: SubscriptionTier = .none
        var detectedExpire: Date?

        os_log("\(self.t)🔄 开始校准当前权益...")

        for await result in StoreKit.Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else {
                os_log("\(self.t)⚠️ 跳过未验证的交易")
                continue
            }

            os_log("\(self.t)📋 检查交易: \(transaction.productID), 类型: \(transaction.productType.rawValue)")

            switch transaction.productType {
            case .autoRenewable:
                let t = StoreService.tier(for: transaction.productID)
                detectedTier = max(detectedTier, t)
                os_log("\(self.t)✅ 自动续费订阅: \(transaction.productID), tier: \(t.rawValue)")

                // 记录最晚的过期时间
                if let exp = transaction.expirationDate {
                    if let cur = detectedExpire {
                        detectedExpire = max(cur, exp)
                    } else {
                        detectedExpire = exp
                    }
                    os_log("\(self.t)⏰ 过期时间: \(exp.fullDateTime)")
                }
            case .nonRenewable:
                let t = StoreService.tier(for: transaction.productID)
                detectedTier = max(detectedTier, t)
                os_log("\(self.t)✅ 非续费订阅: \(transaction.productID), tier: \(t.rawValue)")

                // 对于非续费订阅，检查是否在有效期内
                if let exp = transaction.expirationDate {
                    if exp > Date() {
                        // 仍在有效期内
                        if let cur = detectedExpire {
                            detectedExpire = max(cur, exp)
                        } else {
                            detectedExpire = exp
                        }
                        os_log("\(self.t)⏰ 非续费订阅过期时间: \(exp.fullDateTime)")
                    } else {
                        os_log("\(self.t)⚠️ 非续费订阅已过期: \(exp.fullDateTime)")
                    }
                }
            default:
                os_log("\(self.t)⏭️ 跳过其他类型产品: \(transaction.productID)")
                continue
            }
        }

        os_log("\(self.t)🎯 校准结果: detectedTier=\(detectedTier.rawValue), detectedExpire=\(detectedExpire?.description ?? "nil")")
        update(entitlement: PurchaseInfo(tier: detectedTier, expiresAt: detectedExpire))
    }
}
