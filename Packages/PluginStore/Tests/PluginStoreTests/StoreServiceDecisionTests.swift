import Foundation
import StoreKit
import Testing
@testable import PluginStore

/// `StoreService` 判定内核的单测（续订状态 → 到期时间）。
///
/// ## 可达性说明
/// StoreKit 的 `Product.SubscriptionInfo.Status` 没有公开构造入口（内部持有
/// 不可构造的交易/续订信息），单元测试进程无法构造，因此
/// `computeExpirationDate(from:)` 的整体入口不可达。
/// 生产实现已把「状态 → 到期时间」的判定内核抽为
/// `StoreService.expirationDate(for:transactionExpirationDate:gracePeriodExpirationDate:)`，
/// 本文件直接覆盖该内核的全部状态分支。
@Suite("StoreService 续订到期判定")
struct StoreServiceExpirationDateTests {

    private let distant = Date.distantPast

    @Test("subscribed：采用交易到期时间")
    func subscribedUsesTransactionExpiration() {
        let expiry = Date(timeIntervalSince1970: 1_800_000_000)
        let result = StoreService.expirationDate(
            for: .subscribed,
            transactionExpirationDate: expiry,
            gracePeriodExpirationDate: nil
        )
        #expect(result == expiry)
    }

    @Test("subscribed：交易无到期时间时回退 distantPast")
    func subscribedWithoutExpirationFallsBack() {
        let result = StoreService.expirationDate(
            for: .subscribed,
            transactionExpirationDate: nil,
            gracePeriodExpirationDate: nil
        )
        #expect(result == distant)
    }

    @Test("expired：采用交易到期时间")
    func expiredUsesTransactionExpiration() {
        let expiry = Date(timeIntervalSince1970: 1_700_000_000)
        let result = StoreService.expirationDate(
            for: .expired,
            transactionExpirationDate: expiry,
            gracePeriodExpirationDate: nil
        )
        #expect(result == expiry)
    }

    @Test("expired：交易无到期时间时回退 distantPast")
    func expiredWithoutExpirationFallsBack() {
        let result = StoreService.expirationDate(
            for: .expired,
            transactionExpirationDate: nil,
            gracePeriodExpirationDate: nil
        )
        #expect(result == distant)
    }

    @Test("revoked：一律回退 distantPast（即使交易带到期时间）")
    func revokedAlwaysFallsBack() {
        let expiry = Date(timeIntervalSince1970: 1_800_000_000)
        let result = StoreService.expirationDate(
            for: .revoked,
            transactionExpirationDate: expiry,
            gracePeriodExpirationDate: nil
        )
        #expect(result == distant)
    }

    @Test("inGracePeriod：采用宽限期截止时间")
    func gracePeriodUsesGraceDate() {
        let until = Date(timeIntervalSince1970: 1_750_000_000)
        let result = StoreService.expirationDate(
            for: .inGracePeriod,
            transactionExpirationDate: nil,
            gracePeriodExpirationDate: until
        )
        #expect(result == until)
    }

    @Test("inGracePeriod：无宽限期截止时间时回退 distantPast")
    func gracePeriodWithoutDateFallsBack() {
        let result = StoreService.expirationDate(
            for: .inGracePeriod,
            transactionExpirationDate: nil,
            gracePeriodExpirationDate: nil
        )
        #expect(result == distant)
    }

    @Test("inBillingRetryPeriod：返回当前时间 + 24 小时")
    func billingRetryReturnsNowPlusOneDay() {
        let before = Date.now
        let result = StoreService.expirationDate(
            for: .inBillingRetryPeriod,
            transactionExpirationDate: nil,
            gracePeriodExpirationDate: nil
        )
        let after = Date.now
        // 结果应落在 [before+24h, after+24h] 区间内。
        #expect(result >= before.addingTimeInterval(24 * 3600))
        #expect(result <= after.addingTimeInterval(24 * 3600))
    }

    @Test("未知续订状态：回退 distantPast")
    func unknownStateFallsBack() {
        // 构造一个 StoreKit 未定义的状态值，覆盖 default 分支。
        let unknown = Product.SubscriptionInfo.RenewalState(rawValue: 999)
        let result = StoreService.expirationDate(
            for: unknown,
            transactionExpirationDate: Date(timeIntervalSince1970: 1_800_000_000),
            gracePeriodExpirationDate: Date(timeIntervalSince1970: 1_800_000_000)
        )
        #expect(result == distant)
    }
}

/// `StoreService` 已购归类内核的单测。
///
/// ## 可达性说明
/// StoreKit 的 `Transaction` 没有公开构造入口，单元测试进程无法构造交易对象，
/// 因此 `fetchPurchasedLists` 的遍历体不可达。生产实现已把「交易 → 已购清单」
/// 的判定内核抽为 `StoreService.purchasedProduct(...)`（入参只含产品 ID、
/// 产品类型、购买日期与候选清单），本文件直接覆盖该内核。
@Suite("StoreService 已购归类")
struct StoreServicePurchasedProductTests {

    private func makeProduct(_ id: String, kind: ProductDTO.ProductKind = .nonConsumable) -> ProductDTO {
        ProductDTO(
            id: id,
            displayName: id,
            displayPrice: "¥1",
            price: Decimal(1),
            kind: kind,
            description: ""
        )
    }

    @Test("nonConsumable：命中一次性解锁清单时归为 car")
    func nonConsumableMatchesCar() {
        let car = makeProduct("nonconsumable.car")
        let result = StoreService.purchasedProduct(
            productID: "nonconsumable.car",
            productType: .nonConsumable,
            purchaseDate: Date(),
            cars: [car],
            subscriptions: [],
            nonRenewables: []
        )
        #expect(result == .car(car))
    }

    @Test("nonConsumable：未命中清单时不计入任何已购清单")
    func nonConsumableWithoutMatchIsNil() {
        let result = StoreService.purchasedProduct(
            productID: "nonconsumable.unknown",
            productType: .nonConsumable,
            purchaseDate: Date(),
            cars: [makeProduct("nonconsumable.car")],
            subscriptions: [],
            nonRenewables: []
        )
        #expect(result == nil)
    }

    @Test("autoRenewable：命中订阅清单时归为 subscription")
    func autoRenewableMatchesSubscription() {
        let subscription = makeProduct("com.coffic.netto.monthly", kind: .autoRenewable)
        let result = StoreService.purchasedProduct(
            productID: "com.coffic.netto.monthly",
            productType: .autoRenewable,
            purchaseDate: Date(),
            cars: [],
            subscriptions: [subscription],
            nonRenewables: []
        )
        #expect(result == .subscription(subscription))
    }

    @Test("autoRenewable：未命中清单时不计入任何已购清单")
    func autoRenewableWithoutMatchIsNil() {
        let result = StoreService.purchasedProduct(
            productID: "com.coffic.netto.monthly",
            productType: .autoRenewable,
            purchaseDate: Date(),
            cars: [],
            subscriptions: [],
            nonRenewables: []
        )
        #expect(result == nil)
    }

    @Test("nonRenewable：标准非续订商品且在一年内有效时归为 nonRenewable")
    func nonRenewableWithinOneYearMatches() {
        let item = makeProduct("nonRenewing.standard", kind: .nonRenewable)
        let result = StoreService.purchasedProduct(
            productID: "nonRenewing.standard",
            productType: .nonRenewable,
            purchaseDate: Date(timeIntervalSinceNow: -60 * 60 * 24 * 30),
            cars: [],
            subscriptions: [],
            nonRenewables: [item]
        )
        #expect(result == .nonRenewable(item))
    }

    @Test("nonRenewable：购买已满一年时不再计入（过期）")
    func nonRenewableOlderThanOneYearIsNil() {
        let item = makeProduct("nonRenewing.standard", kind: .nonRenewable)
        let result = StoreService.purchasedProduct(
            productID: "nonRenewing.standard",
            productType: .nonRenewable,
            purchaseDate: Date(timeIntervalSinceNow: -60 * 60 * 24 * 400),
            cars: [],
            subscriptions: [],
            nonRenewables: [item]
        )
        #expect(result == nil)
    }

    @Test("nonRenewable：非标准产品 ID（即使在清单内）不计入")
    func nonRenewableNonStandardIDIsNil() {
        let item = makeProduct("com.coffic.other", kind: .nonRenewable)
        let result = StoreService.purchasedProduct(
            productID: "com.coffic.other",
            productType: .nonRenewable,
            purchaseDate: Date(),
            cars: [],
            subscriptions: [],
            nonRenewables: [item]
        )
        #expect(result == nil)
    }

    @Test("consumable：不计入任何已购清单")
    func consumableIsNil() {
        let result = StoreService.purchasedProduct(
            productID: "consumable.fuel.octane87",
            productType: .consumable,
            purchaseDate: Date(),
            cars: [],
            subscriptions: [],
            nonRenewables: []
        )
        #expect(result == nil)
    }
}
