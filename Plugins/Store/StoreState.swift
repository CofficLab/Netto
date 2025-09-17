import Foundation
import StoreKit
import OSLog
import MagicCore

@MainActor
final class StoreState: ObservableObject, SuperLog {
    nonisolated static let emoji = "💰"
    static let shared = StoreState()

    // MARK: - Published State
    @Published var tier: SubscriptionTier = .none
    @Published var expiresAt: Date? = nil

    // MARK: - Keys
    private enum Keys {
        static let tier = "store.tier"
        static let expiresAt = "store.expiresAt"
        static let lastCheckedAt = "store.lastCheckedAt"
    }

    private init() {
        loadFromDefaults()
    }

    // MARK: - Defaults
    private func loadFromDefaults() {
        let defaults = UserDefaults.standard
        if let raw = defaults.object(forKey: Keys.tier) as? Int, let t = SubscriptionTier(rawValue: raw) {
            self.tier = t
        } else {
            self.tier = .none
        }
        if let ts = defaults.object(forKey: Keys.expiresAt) as? TimeInterval {
            self.expiresAt = Date(timeIntervalSince1970: ts)
        }
    }

    private func saveToDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(tier.rawValue, forKey: Keys.tier)
        if let expiresAt = expiresAt {
            defaults.set(expiresAt.timeIntervalSince1970, forKey: Keys.expiresAt)
        } else {
            defaults.removeObject(forKey: Keys.expiresAt)
        }
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.lastCheckedAt)
    }

    // MARK: - Public API
    func update(tier: SubscriptionTier, expiresAt: Date?) {
        self.tier = tier
        self.expiresAt = expiresAt
        saveToDefaults()
        let expStr = expiresAt.map { Self.formatDate($0) } ?? "nil"
        os_log("\(self.t)🍋 Updated tier=\(tier.rawValue), expiresAt=\(expStr)")
    }

    func clear() {
        update(tier: .none, expiresAt: nil)
    }

    // 校准：从当前权益拉取并写入本地状态
    func calibrateFromCurrentEntitlements() async {
        var detectedTier: SubscriptionTier = .none
        var detectedExpire: Date? = nil
        
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
                    os_log("\(self.t)⏰ 过期时间: \(Self.formatDate(exp))")
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
                        os_log("\(self.t)⏰ 非续费订阅过期时间: \(Self.formatDate(exp))")
                    } else {
                        os_log("\(self.t)⚠️ 非续费订阅已过期: \(Self.formatDate(exp))")
                    }
                }
            default:
                os_log("\(self.t)⏭️ 跳过其他类型产品: \(transaction.productID)")
                continue
            }
        }

        os_log("\(self.t)🎯 校准结果: detectedTier=\(detectedTier.rawValue), detectedExpire=\(detectedExpire?.description ?? "nil")")
        update(tier: detectedTier, expiresAt: detectedExpire)
    }

    // 使用 StoreService 的 tier 判断是否为 Pro 产品
    nonisolated static func isProProductId(_ id: String) -> Bool {
        StoreService.tier(for: id) >= .pro
    }

    // MARK: - Nonisolated Cached Accessors
    /// 从持久化缓存安全读取（后台线程可用）
    nonisolated static func cachedTier() -> SubscriptionTier {
        let defaults = UserDefaults.standard
        if let raw = defaults.object(forKey: Keys.tier) as? Int, let t = SubscriptionTier(rawValue: raw) {
            return t
        }
        return .none
    }

    /// 从持久化缓存安全读取（后台线程可用）
    nonisolated static func cachedExpiresAt() -> Date? {
        let defaults = UserDefaults.standard
        if let ts = defaults.object(forKey: Keys.expiresAt) as? TimeInterval {
            return Date(timeIntervalSince1970: ts)
        }
        return nil
    }

    // MARK: - Date Formatting (Local Timezone)
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.timeZone = .current
        df.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZ"
        return df
    }()

    private static func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
}


