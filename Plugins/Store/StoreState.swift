import Foundation
import StoreKit
import OSLog
import MagicCore

@MainActor
final class StoreState: ObservableObject, SuperLog {
    nonisolated static let emoji = "💰"
    static let shared = StoreState()

    // MARK: - Published State
    @Published var isPro: Bool = false
    @Published var expiresAt: Date? = nil

    // MARK: - Keys
    private enum Keys {
        static let isPro = "store.isPro"
        static let expiresAt = "store.expiresAt"
        static let lastCheckedAt = "store.lastCheckedAt"
    }

    private init() {
        loadFromDefaults()
    }

    // MARK: - Defaults
    private func loadFromDefaults() {
        let defaults = UserDefaults.standard
        self.isPro = defaults.bool(forKey: Keys.isPro)
        if let ts = defaults.object(forKey: Keys.expiresAt) as? TimeInterval {
            self.expiresAt = Date(timeIntervalSince1970: ts)
        }
    }

    private func saveToDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(isPro, forKey: Keys.isPro)
        if let expiresAt = expiresAt {
            defaults.set(expiresAt.timeIntervalSince1970, forKey: Keys.expiresAt)
        } else {
            defaults.removeObject(forKey: Keys.expiresAt)
        }
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.lastCheckedAt)
    }

    // MARK: - Public API
    func update(isPro: Bool, expiresAt: Date?) {
        self.isPro = isPro
        self.expiresAt = expiresAt
        saveToDefaults()
        let expStr = expiresAt.map { Self.formatDate($0) } ?? "nil"
        os_log("\(self.t)🍋 Updated isPro=\(isPro), expiresAt=\(expStr)")
    }

    func clear() {
        update(isPro: false, expiresAt: nil)
    }

    // 校准：从当前权益拉取并写入本地状态
    func calibrateFromCurrentEntitlements() async {
        var detectedIsPro = false
        var detectedExpire: Date? = nil

        for await result in StoreKit.Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }
            switch transaction.productType {
            case .autoRenewable:
                detectedIsPro = detectedIsPro || Self.isProProductId(transaction.productID)
                // 记录最晚的过期时间
                if let exp = transaction.expirationDate {
                    if let cur = detectedExpire {
                        detectedExpire = max(cur, exp)
                    } else {
                        detectedExpire = exp
                    }
                }
            default:
                continue
            }
        }

        update(isPro: detectedIsPro, expiresAt: detectedExpire)
    }

    // 简单的产品ID判断，可按需扩展/改为服务端判定
    nonisolated static func isProProductId(_ id: String) -> Bool {
        return id.contains("netto.pro.") || id.contains("cisum.pro.")
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


