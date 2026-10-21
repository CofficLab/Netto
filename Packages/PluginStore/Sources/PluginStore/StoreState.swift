import Foundation
import OSLog
import StoreKit

final class StoreState: ObservableObject, LogPrefixed {
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
        var transactions: [EntitlementTransaction] = []

        os_log("\(self.t)🔄 开始校准当前权益...")

        for await result in StoreKit.Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else {
                os_log("\(self.t)⚠️ 跳过未验证的交易")
                continue
            }

            os_log("\(self.t)📋 检查交易: \(transaction.productID), 类型: \(transaction.productType.rawValue)")

            transactions.append(
                EntitlementTransaction(
                    productID: transaction.productID,
                    productType: transaction.productType,
                    expirationDate: transaction.expirationDate
                )
            )
        }

        let info = aggregatedEntitlement(from: transactions)

        os_log("\(self.t)🎯 校准结果: detectedTier=\(info.tier.rawValue), detectedExpire=\(info.expiresAt?.description ?? "nil")")
        // 插件关闭（storeTask 已取消）：跳过收尾写入，避免覆盖关闭后的状态。
        guard !Task.isCancelled else {
            os_log("\(self.t)⏭️ 校准任务已取消，跳过写入")
            return
        }
        update(entitlement: info)
    }
}

/// 交易凭据摘要（纯值；把 StoreKit 交易压缩成权益聚合所需的最小信息）。
///
/// 存在意义：StoreKit 的 `Transaction` 没有公开构造入口，单测无法构造交易对象；
/// 权益聚合只用到产品 ID / 产品类型 / 到期时间三个字段，用本摘要承载即可。
struct EntitlementTransaction: Sendable {
    let productID: String
    let productType: Product.ProductType
    let expirationDate: Date?
}

extension StoreState {
    /// 纯逻辑：由交易凭据摘要聚合权益（`calibrateFromCurrentEntitlements` 的聚合内核）。
    ///
    /// - Note: 只统计自动续订与非续订订阅；消耗型/一次性解锁不授予订阅权益。
    ///   非续订订阅仅在「购买日起一年内未过期」时计入到期时间。
    static func aggregatedEntitlement(from transactions: [EntitlementTransaction]) -> PurchaseInfo {
        var detectedTier: SubscriptionTier = .none
        var detectedExpire: Date?

        for transaction in transactions {
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

        return PurchaseInfo(tier: detectedTier, expiresAt: detectedExpire)
    }
}
