import Foundation
import MagicCore
import StoreKit
import SwiftUI

// MARK: - Typealias

public typealias Transaction = StoreKit.Transaction
public typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
public typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

public enum StoreService {
    // MARK: - Data Sources

    public static func loadProductIdToEmojiData() -> [String: String] {
        guard let path = Bundle.main.path(forResource: "Products", ofType: "plist"),
              let plist = FileManager.default.contents(atPath: path),
              let data = try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String: String] else {
            return [:]
        }
        return data
    }

    // MARK: - Product Fetching & Classification

    // 获取产品列表有缓存
    // 因为联网获取后，再断网，一段时间内仍然能得到列表
    // 出现过的情况：
    //  断网，报错
    //  联网得到2个产品，断网，依然得到两个产品
    //  联网得到2个产品，断网，依然得到两个产品，再等等，不报错，得到0个产品
    public static func requestProducts(productIds: some Sequence<String>) async throws -> StoreProductGroupsDTO {
        let idsArray = Array(productIds)
        let storeProducts = try await Product.products(for: idsArray)
        return ProductGroups.classify(storeProducts: storeProducts).toDTO()
    }

    public static func tier(for productId: String) -> SubscriptionTier {
        return .pro
    }

    public static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case let .verified(safe):
            return safe
        }
    }

    public static func computeExpirationDate(from status: Product.SubscriptionInfo.Status?) -> Date {
        guard let status = status else {
            return Date.distantPast
        }

        guard case let .verified(renewalInfo) = status.renewalInfo,
              case let .verified(transaction) = status.transaction else {
            return Date.distantPast
        }

        switch status.state {
        case .subscribed:
            if let expirationDate = transaction.expirationDate {
                return expirationDate
            } else {
                return Date.distantPast
            }
        case .expired:
            if let expirationDate = transaction.expirationDate {
                return expirationDate
            }
            return Date.distantPast
        case .revoked:
            return Date.distantPast
        case .inGracePeriod:
            if let untilDate = renewalInfo.gracePeriodExpirationDate {
                return untilDate
            } else {
                return Date.distantPast
            }
        case .inBillingRetryPeriod:
            return Date.now.addingTimeInterval(24 * 3600)
        default:
            return Date.distantPast
        }
    }
}

// MARK: - Preview

#Preview("Debug") {
    DebugView()
        .inRootView()
        .frame(height: 800)
}

#Preview("Buy") {
    BuySetting()
        .inRootView()
        .frame(height: 800)
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(width: 700)
        .frame(height: 800)
}
