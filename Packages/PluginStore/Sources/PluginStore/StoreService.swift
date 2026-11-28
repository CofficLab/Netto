import Foundation
import KitStoreKit
import OSLog
import ProviderStore
import StoreKit
import SwiftUI

// MARK: - Netpause Store Catalog

/// Netpause 的商品表：商品 ID → 订阅档位。
///
/// 商品 ID 属于 Netpause 商店后台的配置，共享层（`ProviderStore` 契约 +
/// `KitStoreKit` 机制）只定义**映射的形状**（`StoreProductCatalog`），
/// 由本类型提供具体取值。
public struct NetpauseStoreCatalog: StoreProductCatalog {
    /// 商品 ID → 订阅档位。
    public let productTiers: [String: StoreTier]

    public init(productTiers: [String: StoreTier]) {
        self.productTiers = productTiers
    }

    /// 商品表本体。
    public static let shared = NetpauseStoreCatalog(productTiers: [
        // Consumables
        "consumable.fuel.octane87": .none,
        "consumable.fuel.octane89": .none,
        "consumable.fuel.octane91": .none,

        // Non-consumables
        "nonconsumable.car": .none,
        "nonconsumable.utilityvehicle": .none,
        "nonconsumable.racecar": .none,

        // subscription
        "com.coffic.netto.monthly": .pro,
        "com.coffic.netto.annual": .pro,
//        "com.yueyi.netto.ultimate.monthly": .ultimate,
//        "com.yueyi.netto.ultimate.annual": .ultimate,
    ])
}

// MARK: - Typealias

public typealias Transaction = StoreKit.Transaction
public typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
public typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState
public typealias PaymentMode = StoreKit.Product.SubscriptionOffer.PaymentMode

// MARK: - Store Service

/// Netpause 商店服务：驱动共享的 StoreKit 机制层，并提供 Netpause 独有的展示型查询。
///
/// ## 分层
///
/// - **机制**（交易监听、权益校准、商品拉取、购买、恢复、验证）由共享的
///   `KitStoreKit`（`StoreKitService`）提供，各 App 共用同一份实现；
/// - **语义**（哪个商品对应什么档位）由 `NetpauseStoreCatalog` 决定；
/// - 本类型保留 Netpause 独有的展示型查询（已购分组、订阅组状态），这些是
///   Netpause 商店 UI 的需求，不是通用机制。
public enum StoreService: LogPrefixed {
    /// 共享机制层实例。
    private static let sharedService: StoreKitService = {
        let configuration = StoreKitConfiguration(
            productIDs: NetpauseStoreCatalog.shared.allProductIds,
            entitlementStorageKey: StoreState.Keys.purchase,
            lastCheckedAtStorageKey: StoreState.Keys.lastCheckedAt
        )

        return StoreKitService(configuration: configuration) { holding in
            // 机制层的结论 → Netpause 的权益快照（档位映射由 Netpause 商品表决定）。
            let snapshot = NetpauseStoreCatalog.shared.entitlement(
                activeProductIDs: holding.activeSubscriptionProductIDs,
                latestExpiration: holding.latestExpiration
            )
            StoreState.update(entitlement: snapshot)
            NotificationCenter.default.post(name: .storeEntitlementUpdated, object: nil)
        }
    }()

    // MARK: - Transaction Updates

    /// 启动交易监听与初始权益校准。
    ///
    /// 机制部分由共享的 `KitStoreKit` 承担，因此与其它 App 的商店行为一致。
    static func bootstrap() async {
        await sharedService.bootstrap()
    }

    /// 持续监听交易更新直到取消。
    ///
    /// 线程/actor：在插件持有的可取消 Task 中执行；每个交易先校准本地权益再 finish。
    static func observeTransactionUpdates() async {
        await sharedService.startTransactionListener()
        // 监听本身是长驻循环；这里保持等待，让调用方的 Task 承载它。
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
        }
    }

    /// 从当前权益校准本地缓存。
    static func calibrateFromCurrentEntitlements() async {
        await sharedService.calibrateFromCurrentEntitlements()
    }

    // MARK: - Public State Accessors

    /// 当前权益快照。
    public static func currentEntitlement() -> StoreEntitlementSnapshot {
        StoreState.cachedPurchaseInfo()
    }

    /// 读取缓存的权益快照。
    public static func cachedPurchaseInfo() -> StoreEntitlementSnapshot {
        StoreState.cachedPurchaseInfo()
    }

    /// 当前生效档位（过期即免费）。
    public static func tierCached() -> StoreTier {
        StoreState.cachedPurchaseInfo().effectiveTier
    }

    /// 从本地缓存读取过期时间。
    public static func expiresAtCached() -> Date? {
        StoreState.cachedPurchaseInfo().expiresAt
    }

    /// 商品表。
    public static var productCatalog: any StoreProductCatalog {
        NetpauseStoreCatalog.shared
    }

    // MARK: - Data Sources

    /// 全部商品 ID 列表。
    private static func allProductIds() -> [String] {
        NetpauseStoreCatalog.shared.allProductIds
    }

    // MARK: - Product Fetching

    /// 获取「全部」商品：以商品表清单为准。
    public static func fetchAllProducts() async throws -> ProductGroupsDTO {
        try await Self.requestProducts(productIds: Self.allProductIds())
    }

    /// 按 ID 清单请求商品详情并分组。
    static func requestProducts(productIds: some Sequence<String>) async throws -> ProductGroupsDTO {
        let idsArray = Array(productIds)
        let storeProducts = try await Product.products(for: idsArray)
        return ProductGroupsDTO(products: storeProducts)
    }

    /// 获取所有订阅组（按订阅组 ID 聚合订阅类商品）。
    public static func fetchAllSubscriptionGroups() async throws -> [SubscriptionGroupDTO] {
        let products = try await fetchAllProducts()
        return products.subscriptionGroups
    }

    // MARK: - Purchased Fetching

    /// 根据当前账户的交易凭据筛选并归类「已购」产品列表。
    public static func fetchPurchasedLists(
        cars: [ProductDTO],
        subscriptions: [ProductDTO],
        nonRenewables: [ProductDTO]
    ) async -> (
        cars: [ProductDTO],
        nonRenewables: [ProductDTO],
        subscriptions: [ProductDTO]
    ) {
        var purchasedCars: [ProductDTO] = []
        var purchasedSubscriptions: [ProductDTO] = []
        var purchasedNonRenewableSubscriptions: [ProductDTO] = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction: Transaction = try checkVerified(result)

                switch Self.purchasedProduct(
                    productID: transaction.productID,
                    productType: transaction.productType,
                    purchaseDate: transaction.purchaseDate,
                    cars: cars,
                    subscriptions: subscriptions,
                    nonRenewables: nonRenewables
                ) {
                case .car(let car):
                    purchasedCars.append(car)
                case .nonRenewable(let nonRenewable):
                    purchasedNonRenewableSubscriptions.append(nonRenewable)
                case .subscription(let subscription):
                    purchasedSubscriptions.append(subscription)
                case nil:
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

    /// 已购商品归类（纯值；`fetchPurchasedLists` 的判定结果）。
    enum PurchasedProduct: Sendable, Equatable {
        /// 一次性解锁（nonConsumable）。
        case car(ProductDTO)
        /// 非续订订阅（nonRenewable，且仍在有效期内）。
        case nonRenewable(ProductDTO)
        /// 自动续订订阅（autoRenewable）。
        case subscription(ProductDTO)
    }

    /// 纯逻辑：单笔交易的已购归类（`fetchPurchasedLists` 的判定内核）。
    ///
    /// 抽成独立方法的原因：StoreKit 的 `Transaction` 没有公开构造入口，
    /// 单测无法构造交易对象；把「交易 → 已购清单」的判定内核独立出来后，
    /// 可直接用 `Product.ProductType` 覆盖全部分类分支。
    static func purchasedProduct(
        productID: String,
        productType: Product.ProductType,
        purchaseDate: Date,
        cars: [ProductDTO],
        subscriptions: [ProductDTO],
        nonRenewables: [ProductDTO],
        now: Date = Date()
    ) -> PurchasedProduct? {
        switch productType {
        case .nonConsumable:
            guard let car = cars.first(where: { $0.id == productID }) else { return nil }
            return .car(car)
        case .nonRenewable:
            guard let nonRenewable = nonRenewables.first(where: { $0.id == productID }),
                  productID == "nonRenewing.standard" else { return nil }
            let expirationDate = Calendar(identifier: .gregorian)
                .date(byAdding: DateComponents(year: 1), to: purchaseDate)!
            guard now < expirationDate else { return nil }
            return .nonRenewable(nonRenewable)
        case .autoRenewable:
            guard let subscription = subscriptions.first(where: { $0.id == productID }) else { return nil }
            return .subscription(subscription)
        default:
            return nil
        }
    }

    // MARK: - Tier & Verification

    /// 查询商品对应的档位。
    public static func tier(for productId: String) -> StoreTier {
        NetpauseStoreCatalog.shared.tier(for: productId)
    }

    /// 校验 StoreKit 的验证结果。未验证的交易一律拒绝。
    public static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case let .verified(safe):
            return safe
        }
    }

    // MARK: - Pay

    /// 发起购买（按商品 ID）。
    @discardableResult
    public static func purchase(productID: String) async throws -> StoreKitTransactionSummary? {
        try await sharedService.purchase(productID: productID)
    }

    /// 发起购买（按商品 DTO）。
    @discardableResult
    public static func purchase(_ product: ProductDTO) async throws -> StoreKitTransactionSummary? {
        try await purchase(productID: product.id)
    }

    /// 与 App Store 同步凭据的动作（默认 `AppStore.sync()`）。
    ///
    /// 抽成可替换入口：回归测试需要在没有商店会话的进程里验证
    /// 「恢复确实触发了同步」这一行为。
    @MainActor
    static var appStoreSync: () async throws -> Void = { try await AppStore.sync() }

    /// 恢复购买。
    ///
    /// StoreKit 2 没有独立的 restore API：恢复走 `AppStore.sync()` 把商店端的
    /// 凭据推回本机，然后校准本地权益缓存。只做校准在重装或换机后读到的
    /// 仍是空缓存，恢复按钮会形同虚设。
    ///
    /// 用户取消 App Store 登录不算失败。
    @MainActor
    public static func restorePurchases() async throws {
        _ = try await StoreRestoreRunner.run(dependencies: StoreRestoreDependencies(
            sync: { try await appStoreSync() },
            calibrate: { await sharedService.calibrateFromCurrentEntitlements() }
        ))
    }

    // MARK: - Subscription Status

    /// 计算订阅到期时间（按订阅状态）。
    public static func computeExpirationDate(from status: Product.SubscriptionInfo.Status?) -> Date {
        guard let status = status else {
            return Date.distantPast
        }

        guard case let .verified(renewalInfo) = status.renewalInfo,
              case let .verified(transaction) = status.transaction else {
            return Date.distantPast
        }

        return expirationDate(
            for: status.state,
            transactionExpirationDate: transaction.expirationDate,
            gracePeriodExpirationDate: renewalInfo.gracePeriodExpirationDate
        )
    }

    /// 纯逻辑：续订状态 → 到期时间。
    ///
    /// 抽成独立方法的原因：StoreKit 的 `Product.SubscriptionInfo.Status` 没有公开
    /// 构造入口（内部持有不可构造的交易/续订信息），单元测试进程无法构造，
    /// 因此把「状态 → 到期时间」的判定内核独立出来，让全部分支可被单测覆盖。
    ///
    /// - Parameters:
    ///   - state: 续订状态。
    ///   - transactionExpirationDate: 交易的到期时间。
    ///   - gracePeriodExpirationDate: 宽限期的截止时间。
    /// - Returns: 到期时间；无法确定时为 `Date.distantPast`。
    public static func expirationDate(
        for state: RenewalState,
        transactionExpirationDate: Date?,
        gracePeriodExpirationDate: Date?
    ) -> Date {
        switch state {
        case .subscribed:
            return transactionExpirationDate ?? Date.distantPast
        case .expired:
            return transactionExpirationDate ?? Date.distantPast
        case .revoked:
            return Date.distantPast
        case .inGracePeriod:
            return gracePeriodExpirationDate ?? Date.distantPast
        case .inBillingRetryPeriod:
            return Date.now.addingTimeInterval(24 * 3600)
        default:
            return Date.distantPast
        }
    }

    /// 检查订阅组状态，返回可用的订阅商品与最高档位条目。
    public static func inspectSubscriptionStatus(_ reason: String, verbose: Bool = false) async throws -> (
        subscriptions: [ProductDTO],
        statuses: [StoreSubscriptionStatusDTO],
        highestProduct: ProductDTO?,
        highestStatus: StoreSubscriptionStatusDTO?
    ) {
        if verbose {
            os_log("\(self.t)Checking subscription status, reason: \(reason)")
        }

        let products = try await Self.requestProducts(productIds: Self.allProductIds())
        let subscriptions = products.subscriptions

        if subscriptions.isEmpty {
            return (subscriptions: [], statuses: [], highestProduct: nil, highestStatus: nil)
        }

        guard let subscription = subscriptions.first,
              let statuses = subscription.subscription?.status else {
            return (subscriptions: subscriptions, statuses: [], highestProduct: nil, highestStatus: nil)
        }

        if statuses.isEmpty {
            return (subscriptions: subscriptions, statuses: [], highestProduct: nil, highestStatus: nil)
        }

        let snapshots = statuses.map {
            SubscriptionStatusSnapshot(
                state: $0.state,
                currentProductID: $0.currentProductID
            )
        }

        let highestIndex = highestActiveSubscriptionStatusIndex(
            subscriptions: subscriptions,
            statuses: snapshots
        )
        let highestStatus = highestIndex.map { statuses[$0] }
        let productsByID = subscriptionsByID(subscriptions)
        let highestProduct = highestIndex
            .flatMap { snapshots[$0].currentProductID }
            .flatMap { productsByID[$0] }

        return (subscriptions: subscriptions, statuses: statuses, highestProduct: highestProduct, highestStatus: highestStatus)
    }

    /// 找出最高档位的有效订阅状态索引（跳过过期与已撤销）。
    static func highestActiveSubscriptionStatusIndex(
        subscriptions: [ProductDTO],
        statuses: [SubscriptionStatusSnapshot]
    ) -> Int? {
        let productsByID = subscriptionsByID(subscriptions)
        var highestIndex: Int?
        var highestTier: StoreTier = .none

        for (index, status) in statuses.enumerated() {
            switch status.state {
            case RenewalState.expired.rawValue,
                 RenewalState.revoked.rawValue:
                continue
            default:
                break
            }

            guard let productID = status.currentProductID,
                  productsByID[productID] != nil else {
                continue
            }

            let tier = NetpauseStoreCatalog.shared.tier(for: productID)
            if highestIndex == nil || tier > highestTier {
                highestIndex = index
                highestTier = tier
            }
        }

        return highestIndex
    }

    private static func subscriptionsByID(_ subscriptions: [ProductDTO]) -> [String: ProductDTO] {
        subscriptions.reduce(into: [:]) { result, subscription in
            result[subscription.id] = subscription
        }
    }
}

// MARK: - Subscription Status Snapshot

/// 订阅状态快照（诊断视图用）。
struct SubscriptionStatusSnapshot: Equatable, Sendable {
    let state: RenewalState.RawValue
    let currentProductID: String?
}

// MARK: - Error

public enum StoreError: Error, LocalizedError {
    case failedVerification
    case canNotGetProducts

    public var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "failedVerification"
        case .canNotGetProducts:
            return "发生错误：无法获取产品"
        }
    }
}
