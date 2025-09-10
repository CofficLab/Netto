import Foundation
import MagicCore
import OSLog
import StoreKit
import SwiftUI

class StoreProvider: ObservableObject, SuperLog {
    static let emoji = "💰"

    @Published private(set) var cars: [StoreProductDTO]
    @Published private(set) var fuel: [StoreProductDTO]
    @Published private(set) var subscriptions: [StoreProductDTO]
    @Published private(set) var nonRenewables: [StoreProductDTO]

    @Published private(set) var purchasedCars: [StoreProductDTO] = []
    @Published private(set) var purchasedNonRenewableSubscriptions: [StoreProductDTO] = []
    @Published private(set) var purchasedSubscriptions: [StoreProductDTO] = []
    @Published private(set) var subscriptionGroupStatus: RenewalState?

    @Published var currentSubscription: Product?
    @Published var status: Product.SubscriptionInfo.Status?

    var updateListenerTask: Task<Void, Error>?

    private let productIdToEmoji: [String: String]

    init(verbose: Bool = false) {
        if verbose {
            os_log("\(Self.t)初始化")
        }

        productIdToEmoji = StoreService.loadProductIdToEmojiData()

        // 初始化产品列表，稍后填充
        cars = []
        fuel = []
        subscriptions = []
        nonRenewables = []

        // Start a transaction listener as close to app launch as possible so you don't miss any transactions.
        updateListenerTask = listenForTransactions("🐛 Store 初始化")
    }

    // MARK: - Setter

    func setCars(_ cars: [StoreProductDTO]) {
        self.cars = cars
    }
    
    func setFuel(_ fuel: [StoreProductDTO]) {
        self.fuel = fuel
    }

    func setSubscriptions(_ subscriptions: [StoreProductDTO]) {
        self.subscriptions = subscriptions
    }

    func setNonRenewables(_ nonRenewables: [StoreProductDTO]) {
        self.nonRenewables = nonRenewables
    }

    func setPurchasedCars(_ purchasedCars: [StoreProductDTO]) {
        self.purchasedCars = purchasedCars
    }

    func setPurchasedNonRenewableSubscriptions(_ purchasedNonRenewableSubscriptions: [StoreProductDTO]) {
        self.purchasedNonRenewableSubscriptions = purchasedNonRenewableSubscriptions
    }

    func setPurchasedSubscriptions(_ purchasedSubscriptions: [StoreProductDTO]) {
        self.purchasedSubscriptions = purchasedSubscriptions
    }

    func setSubscriptionGroupStatus(_ subscriptionGroupStatus: RenewalState) {
        self.subscriptionGroupStatus = subscriptionGroupStatus
    }

    func setSubscriptionGroupStatus(_ state: RenewalState?, reason: String, verbose: Bool = false) {
        if verbose {
            os_log("\(self.t)更新订阅组的状态，因为 \(reason)")
        }

        self.subscriptionGroupStatus = state
    }

    func setSubscription(_ sub: Product?, verbose: Bool = false) {
        if verbose {
            os_log("\(self.t)StoreManger 更新订阅计划为 \(sub?.displayName ?? "-")")
        }

        self.currentSubscription = sub
    }

    func setStatus(_ status: Product.SubscriptionInfo.Status?, verbose: Bool = false) {
        if verbose {
            os_log("\(self.t)StoreManger 更新订阅状态")
        }

        self.status = status
    }

    func setPurchased(_ reason: String, verbose: Bool = false) async {
        if verbose {
            os_log("\(self.t)更新已购列表，因为 -> \(reason)")
        }

        let lists = await StoreService.fetchPurchasedLists(
            cars: cars,
            subscriptions: subscriptions,
            nonRenewables: nonRenewables
        )

        self.purchasedCars = lists.cars
        self.purchasedNonRenewableSubscriptions = lists.nonRenewables
        self.purchasedSubscriptions = lists.subscriptions

//        let subscriptionGroupStatus = try? await subscriptions.first?.subscription?.status.first?.state
//        updateSubscriptionGroupStatus(subscriptionGroupStatus, reason: "\(reason)")
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func listenForTransactions(_ reason: String, verbose: Bool = false) -> Task<Void, Error> {
        if verbose {
            os_log("\(self.t)ListenForTransactions，因为 -> \(reason)")
        }

        return Task.detached {
            // Iterate through any transactions that don't come from a direct call to `purchase()`.
//            for await result in Transaction.updates {
//                do {
//                    let transaction = try self.checkVerified(result)
//
//                    // Deliver products to the user.
//                    await self.updatePurchased("\(reason) -> 🐛 ListenForTransactions")
//
//                    // Always finish a transaction.
//                    await transaction.finish()
//                } catch {
//                    // StoreKit has a transaction that fails verification. Don't deliver content to the user.
//                    print("Transaction failed verification")
//                }
//            }
        }
    }

    func requestProducts(_ reason: String, verbose: Bool = true) async throws {
        if verbose {
            os_log("\(self.t)请求 App Store 获取产品列表，因为 -> \(reason)")
        }

        do {
            let groups = try await StoreService.requestProducts(productIds: productIdToEmoji.keys)

            self.setCars(groups.cars)
            self.setSubscriptions(groups.subscriptions)
            self.setNonRenewables(groups.nonRenewables)
            self.setFuel(groups.fuel)
        } catch let error {
            throw error
        }
    }

    // MARK: 购买与支付

    func purchase(_ product: StoreProductDTO) async throws -> Transaction? {
        return try await StoreService.purchase(product)
    }

    func isPurchased(_ product: StoreProductDTO) async throws -> Bool {
        // Determine whether the user purchases a given product.
        switch product.kind {
        case .nonRenewable:
            return purchasedNonRenewableSubscriptions.contains(product)
        case .nonConsumable:
            return purchasedCars.contains(product)
        case .autoRenewable:
            return purchasedSubscriptions.contains(product)
        default:
            return false
        }
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        try StoreService.checkVerified(result)
    }

    func emoji(for productId: String) -> String {
        return productIdToEmoji[productId]!
    }

    // Get a subscription's level of service using the product ID.
    func tier(for productId: String) -> SubscriptionTier {
        StoreService.tier(for: productId)
    }

    // MAKR: 更新订阅状态

    func updateSubscriptionStatus(_ reason: String, _ completion: ((Error?) -> Void)? = nil, verbose: Bool = false) async {
        if verbose {
            os_log("\(self.t)StoreManger 检查订阅状态，因为 -> \(reason)")
        }
        
        try? await StoreService.inspectSubscriptionStatus(reason,verbose: true)
    }

    // MARK: 获取Pro版本失效时间

    func getExpirationDate() -> Date {
        os_log("\(self.t)💰 获取失效时间")
        let date = StoreService.computeExpirationDate(from: status)
        return date
    }
}

// MARK: - Error

public enum StoreError: Error, LocalizedError {
    case failedVerification
    case canNotGetProducts

    public var errorDescription: String? {
        switch self {
        case .failedVerification:
            "failedVerification"
        case .canNotGetProducts:
            "发生错误：无法获取产品"
        }
    }
}

// Define our app's subscription tiers by level of service, in ascending order.
public enum SubscriptionTier: Int, Comparable {
    case none = 0
    case pro = 1

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Preview

#Preview("BuyView") {
    PurchaseView(showCloseButton: false)
        .inRootView()
        .frame(height: 800)
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(height: 600)
}
