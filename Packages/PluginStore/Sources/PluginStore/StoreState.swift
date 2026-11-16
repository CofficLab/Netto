import Foundation
import OSLog
import ProviderStore
import StoreKit

/// Netto 权益缓存：把权益快照持久化到 `UserDefaults`。
///
/// 共享的 `KitStoreKit` 负责**机制**（何时校准、如何读交易），本类型负责
/// **Netto 侧的持久化格式**。
final class StoreState: ObservableObject, LogPrefixed {
    nonisolated static let emoji = "💰"

    // MARK: - Keys

    /// 持久化 key。
    ///
    /// 与共享机制层共用同一组 key，保证两边读到的是同一份缓存。
    enum Keys {
        static let purchase = "store.purchase"
        static let lastCheckedAt = "store.lastCheckedAt"
    }

    // MARK: - Public API

    /// 读取缓存的权益快照。
    static func cachedPurchaseInfo() -> StoreEntitlementSnapshot {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: Keys.purchase),
           let snapshot = try? JSONDecoder().decode(StoreEntitlementSnapshot.self, from: data) {
            return snapshot
        }
        return .none
    }

    /// 写入权益快照。
    static func update(entitlement: StoreEntitlementSnapshot) {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(entitlement) {
            defaults.set(data, forKey: Keys.purchase)
        }
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.lastCheckedAt)
        os_log("\(self.t)🍋 Updated tier=\(entitlement.tier.rawValue)")
        // 模块内权益变更桥：PluginStore.observeEntitlement() 消费。
        NotificationCenter.default.post(name: .storeEntitlementUpdated, object: nil)
    }

    /// 清除权益缓存。
    static func clear() {
        update(entitlement: .none)
    }
}

// MARK: - Snapshot Display

extension StoreEntitlementSnapshot {
    /// 到期时间的展示字符串。
    ///
    /// 展示文案属于 App 侧，因此不放在共享契约层。
    var expiresAtString: String {
        guard let expiresAt else { return "nil" }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        let timeStr = formatter.string(from: expiresAt)

        // 延迟1分钟，方便测试
        let isExpired = self.isExpired ? "[过期了]" : "[没过期]"

        return timeStr + isExpired
    }
}
