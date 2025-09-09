import Foundation
import MagicCore
import StoreKit
import SwiftUI
import OSLog

// MARK: - Typealias

public typealias Transaction = StoreKit.Transaction
public typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
public typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

public enum StoreService: SuperLog {
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

    // MARK: - Purchased Fetching

    public static func fetchPurchasedLists(
        cars: [StoreProductDTO],
        subscriptions: [StoreProductDTO],
        nonRenewables: [StoreProductDTO]
    ) async -> (
        cars: [StoreProductDTO],
        nonRenewables: [StoreProductDTO],
        subscriptions: [StoreProductDTO]
    ) {
        var purchasedCars: [StoreProductDTO] = []
        var purchasedSubscriptions: [StoreProductDTO] = []
        var purchasedNonRenewableSubscriptions: [StoreProductDTO] = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction: Transaction = try checkVerified(result)

                switch transaction.productType {
                case .nonConsumable:
                    if let car = cars.first(where: { $0.id == transaction.productID }) {
                        purchasedCars.append(car)
                    }
                case .nonRenewable:
                    if let nonRenewable = nonRenewables.first(where: { $0.id == transaction.productID }),
                       transaction.productID == "nonRenewing.standard" {
                        let currentDate = Date()
                        let expirationDate = Calendar(identifier: .gregorian)
                            .date(byAdding: DateComponents(year: 1), to: transaction.purchaseDate)!
                        if currentDate < expirationDate {
                            purchasedNonRenewableSubscriptions.append(nonRenewable)
                        }
                    }
                case .autoRenewable:
                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        purchasedSubscriptions.append(subscription)
                    }
                default:
                    break
                }
            } catch {
                // Ignore unverified transactions for purchased list calculation.
                continue
            }
        }

        return (
            cars: purchasedCars,
            nonRenewables: purchasedNonRenewableSubscriptions,
            subscriptions: purchasedSubscriptions
        )
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
    
    static private func purchase(_ product: Product) async throws -> Transaction? {
        os_log("\(self.t)去支付")

        #if os(visionOS)
            return nil
        #else
            // Begin purchasing the `Product` the user selects.
            let result = try await product.purchase()

            switch result {
            case let .success(verification):
                os_log("\(self.t)支付成功，验证")
                // Check whether the transaction is verified. If it isn't,
                // this function rethrows the verification error.
                let transaction = try checkVerified(verification)

                os_log("\(self.t)支付成功，验证成功")
                // The transaction is verified. Deliver content to the user.
//                await updatePurchased("支付并验证成功")

                // Always finish a transaction.
                await transaction.finish()

                return transaction
            case .userCancelled, .pending:
                os_log("\(self.t)取消或pending")
                return nil
            default:
                os_log("\(self.t)支付结果 \(String(describing: result))")
                return nil
            }
        #endif
    }

    static func purchase(_ product: StoreProductDTO) async throws -> Transaction? {
        // Resolve StoreKit.Product by id and reuse the existing purchase flow
        let products = try await Product.products(for: [product.id])
        guard let storekitProduct = products.first else { return nil }
        return try await purchase(storekitProduct)
    }
    
    static func updateSubscriptionStatus(_ reason: String, verbose: Bool = true) async throws {
        if verbose {
            print("检查订阅状态")
            os_log("\(self.t)检查订阅状态，因为 -> \(reason)")
        }

        // 订阅组可以多个
        //  1. 专业版订阅计划
        //    1.1 按年，ID: com.coffic.pro.year
        //    1.2 按月，ID: com.coffic.pro.month
        //  2. 旗舰版订阅计划
        //    2.1 按年，ID: com.coffic.ultmate.year
        //    2.2 按月，ID: com.coffic.ultmate.month
        
        let products = try await Self.requestProducts(productIds: StoreService.loadProductIdToEmojiData().keys)
        
        // 获取当前的可订阅的产品列表，也就是
        /// - com.coffic.pro.year
        /// - com.coffic.pro.month
        /// - com.coffic.ultmate.year
        /// - com.coffic.ultmate.month
        let subscriptions = products.subscriptions
        
        if subscriptions.isEmpty {
            return
        } 

        // 输出 subscriptions
        print("当前的可订阅的产品列表：")
        for subscription in subscriptions {
            print("\(subscription.id)")
            print(" - des: \(subscription.description)")
        }
        
        // 订阅组可以多个，但这里仅有1个
        do {
            // This app has only one subscription group, so products in the subscriptions
            // array all belong to the same group. The statuses that
            // `product.subscription.status` returns apply to the entire subscription group.
            guard let subscription = subscriptions.first,
                  let statuses = subscription.subscription?.status else {
                print("products.subscriptions 是空的")
                return
            }
            
            if statuses.isEmpty {
                print("statuses 是空的，表示对于当前订阅组，没有订阅状态")
                return
            }

            var highestStatus: StoreSubscriptionStatusDTO?
            var highestProduct: StoreProductDTO?

            if verbose {
                os_log("\(self.t)StoreManger 检查订阅状态，statuses.count -> \(statuses.count)")
            }

            // Iterate through `statuses` for this subscription group and find
            // the `Status` with the highest level of service that isn't
            // in an expired or revoked state. For example, a customer may be subscribed to the
            // same product with different levels of service through Family Sharing.
            for status in statuses {
                switch status.state {
                case
                    Product.SubscriptionInfo.RenewalState.expired.rawValue,
                    Product.SubscriptionInfo.RenewalState.revoked.rawValue:
                    if verbose {
                        os_log("\(self.t)检查订阅状态 -> 超时或被撤销")
                    }

                    continue
                case Product.SubscriptionInfo.RenewalState.subscribed.rawValue:
                    print("检查订阅状态 -> Subscribed")
                default:
                    let renewalInfo: RenewalInfo = try checkVerified(status.renewalInfo)

                    // Find the first subscription product that matches the subscription status renewal info by comparing the product IDs.
                    guard let newSubscription = subscriptions.first(where: { $0.id == renewalInfo.currentProductID }) else {
                        continue
                    }

                    guard let currentProduct = highestProduct else {
                        highestStatus = status
                        highestProduct = newSubscription
                        continue
                    }

                    let highestTier = tier(for: currentProduct.id)
                    let newTier = tier(for: renewalInfo.currentProductID)

                    if newTier > highestTier {
                        highestStatus = status
                        highestProduct = newSubscription
                    }
                }
            }
        } catch {
            os_log(.error, "\(self.t) 💰 StoreManger 检查订阅状态，出错 -> \(error.localizedDescription)")
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
    PurchaseView()
        .inRootView()
        .frame(height: 800)
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(width: 700)
        .frame(height: 800)
}
