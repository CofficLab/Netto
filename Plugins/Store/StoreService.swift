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

    /// 私有：读取配置中的全部商品 ID 列表
    private static func allProductIds() -> [String] {
        Array(loadProductIdToEmojiData().keys)
    }

    /// 私有：读取订阅组 ID 到显示名的映射（若无配置则为空）
    private static func loadSubscriptionGroupIdToName() -> [String: String] {
        guard let path = Bundle.main.path(forResource: "SubscriptionGroups", ofType: "plist"),
              let plist = FileManager.default.contents(atPath: path),
              let data = try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String: String] else {
            return [:]
        }
        return data
    }

    /// 订阅组显示名（若未配置友好名则回退为组 ID）
    public static func subscriptionGroupDisplayName(for groupId: String) -> String {
        let map = loadSubscriptionGroupIdToName()
        return map[groupId] ?? groupId
    }

    // MARK: - Product Fetching & Classification

    // 获取产品列表有缓存
    // 因为联网获取后，再断网，一段时间内仍然能得到列表
    // 出现过的情况：
    //  断网，报错
    //  联网得到2个产品，断网，依然得到两个产品
    //  联网得到2个产品，断网，依然得到两个产品，再等等，不报错，得到0个产品
    private static func requestProducts(productIds: some Sequence<String>) async throws -> StoreProductGroupsDTO {
        let idsArray = Array(productIds)
        let storeProducts = try await Product.products(for: idsArray)
        return ProductGroups.classify(storeProducts: storeProducts).toDTO()
    }

    /// 获取“全部”商品的封装：先读取产品 ID 清单，再按清单请求详情并分组。
    ///
    /// - Note: 本方法并非真正从服务器“枚举全部商品”，而是以本地/远端配置的产品 ID 清单为准。
    /// - Returns: `StoreProductGroupsDTO`，包含 cars / subscriptions / nonRenewables / fuel 等分组。
    public static func fetchAllProducts() async throws -> StoreProductGroupsDTO {
        let ids = Self.allProductIds()
        return try await Self.requestProducts(productIds: ids)
    }

    /// 获取所有订阅组（按订阅组 ID 聚合订阅类商品）。
    ///
    /// - Returns: 字典：`[subscriptionGroupID: [StoreProductDTO]]`。
    /// - Note: 依赖 `fetchAllProducts()`，因此实际结果受产品 ID 清单约束。
    public static func fetchAllSubscriptionGroups() async throws -> [String: [StoreProductDTO]] {
        let groups = try await fetchAllProducts()
        let subscriptions = groups.subscriptions

        var result: [String: [StoreProductDTO]] = [:]
        for product in subscriptions {
            let groupId = product.subscription?.subscriptionGroupID ?? "unknown"
            result[groupId, default: []].append(product)
        }
        return result
    }

    // MARK: - Purchased Fetching

    /// 根据当前账户的交易凭据（Transaction.currentEntitlements）筛选并归类“已购”产品列表。
    ///
    /// - Important: 该方法不会主动拉取产品，请先通过 `requestProducts(productIds:)` 获取到完整的产品分组，
    ///   再将各分组传入本方法进行过滤与匹配。
    ///
    /// - Parameters:
    ///   - cars: 已获取到的非消耗型（如一次性解锁）产品列表。
    ///   - subscriptions: 已获取到的自动续订订阅产品列表。
    ///   - nonRenewables: 已获取到的非续订订阅产品列表。
    ///
    /// - Returns: 按交易凭据过滤后的三类“已购清单”元组：
    ///   `(cars: [StoreProductDTO], nonRenewables: [StoreProductDTO], subscriptions: [StoreProductDTO])`。
    ///
    /// - Note:
    ///   - 未通过验证的交易会被忽略（使用 `checkVerified` 校验）。
    ///   - 非续订订阅仅在 `productID == "nonRenewing.standard"` 且“购买日起一年内未过期”时计入。
    ///   - 方法为 `async`，因为 `Transaction.currentEntitlements` 为异步序列。
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
    
    /// 巡检订阅组状态并返回有价值的数据（订阅产品、状态明细、最高等级条目）。
    ///
    /// - Parameters:
    ///   - reason: 调用原因，便于日志排查。
    ///   - verbose: 是否输出详细日志。
    /// - Returns: 三元组 `(subscriptions, statuses, highestProduct, highestStatus)`：
    ///   - `subscriptions`: 当前可用的订阅类产品（同一组）。
    ///   - `statuses`: 来自订阅组的状态数组（已映射为 `StoreSubscriptionStatusDTO`）。
    ///   - `highestProduct`: 当前最高等级对应的产品（若能判定）。
    ///   - `highestStatus`: 当前最高等级对应的状态（若能判定）。
    static func inspectSubscriptionStatus(_ reason: String, verbose: Bool = true) async throws -> (
        subscriptions: [StoreProductDTO],
        statuses: [StoreSubscriptionStatusDTO],
        highestProduct: StoreProductDTO?,
        highestStatus: StoreSubscriptionStatusDTO?
    ) {
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
            return (subscriptions: [], statuses: [], highestProduct: nil, highestStatus: nil)
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
                return (subscriptions: subscriptions, statuses: [], highestProduct: nil, highestStatus: nil)
            }
            
            if statuses.isEmpty {
                print("statuses 是空的，表示对于当前订阅组，没有订阅状态")
                return (subscriptions: subscriptions, statuses: [], highestProduct: nil, highestStatus: nil)
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

            return (subscriptions: subscriptions, statuses: statuses, highestProduct: highestProduct, highestStatus: highestStatus)
        } catch {
            os_log(.error, "\(self.t) 💰 StoreManger 检查订阅状态，出错 -> \(error.localizedDescription)")
            return (subscriptions: subscriptions, statuses: [], highestProduct: nil, highestStatus: nil)
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
