import Foundation
import StoreKit
import Testing
@testable import PluginStore

/// `StoreState` 权益聚合内核的单测。
///
/// ## 可达性说明
/// StoreKit 的 `Transaction` 没有公开构造入口，单元测试进程无法构造交易对象，
/// 因此 `calibrateFromCurrentEntitlements` 的遍历体不可达。生产实现已把
/// 「交易凭据 → 权益」聚合内核抽为 `StoreState.aggregatedEntitlement(from:)`，
/// 本文件直接覆盖该内核。
@Suite("StoreState 权益聚合")
struct StoreStateAggregatedEntitlementTests {

    private func makeTransaction(
        _ productID: String,
        type: Product.ProductType,
        expirationDate: Date? = nil
    ) -> EntitlementTransaction {
        EntitlementTransaction(
            productID: productID,
            productType: type,
            expirationDate: expirationDate
        )
    }

    @Test("空交易列表：等级 none、无到期时间")
    func emptyTransactionsYieldNone() {
        let info = StoreState.aggregatedEntitlement(from: [])
        #expect(info.tier == .none)
        #expect(info.expiresAt == nil)
    }

    @Test("autoRenewable：取产品等级并记录到期时间")
    func autoRenewableGrantsTierAndExpiry() {
        let expiry = Date(timeIntervalSince1970: 1_800_000_000)
        let info = StoreState.aggregatedEntitlement(from: [
            makeTransaction("com.coffic.netto.monthly", type: .autoRenewable, expirationDate: expiry)
        ])
        #expect(info.tier == .pro)
        #expect(info.expiresAt == expiry)
    }

    @Test("autoRenewable：无到期时间时只授予等级")
    func autoRenewableWithoutExpiry() {
        let info = StoreState.aggregatedEntitlement(from: [
            makeTransaction("com.coffic.netto.monthly", type: .autoRenewable)
        ])
        #expect(info.tier == .pro)
        #expect(info.expiresAt == nil)
    }

    @Test("autoRenewable：多笔交易取最晚的到期时间")
    func autoRenewableKeepsLatestExpiry() {
        let earlier = Date(timeIntervalSince1970: 1_700_000_000)
        let later = Date(timeIntervalSince1970: 1_900_000_000)
        let info = StoreState.aggregatedEntitlement(from: [
            makeTransaction("com.coffic.netto.monthly", type: .autoRenewable, expirationDate: later),
            makeTransaction("com.coffic.netto.annual", type: .autoRenewable, expirationDate: earlier)
        ])
        #expect(info.tier == .pro)
        #expect(info.expiresAt == later)
    }

    @Test("nonRenewable：未过期时计入到期时间")
    func nonRenewableWithinValidityGrantsExpiry() {
        let expiry = Date(timeIntervalSinceNow: 60 * 60 * 24)
        let info = StoreState.aggregatedEntitlement(from: [
            makeTransaction("com.coffic.netto.monthly", type: .nonRenewable, expirationDate: expiry)
        ])
        #expect(info.tier == .pro)
        #expect(info.expiresAt == expiry)
    }

    @Test("nonRenewable：已过期时只授予等级、不记到期时间")
    func nonRenewableExpiredKeepsTierOnly() {
        let info = StoreState.aggregatedEntitlement(from: [
            makeTransaction("com.coffic.netto.monthly", type: .nonRenewable, expirationDate: Date(timeIntervalSinceNow: -3600))
        ])
        #expect(info.tier == .pro)
        #expect(info.expiresAt == nil)
    }

    @Test("nonRenewable：多笔交易取最晚的到期时间")
    func nonRenewableKeepsLatestExpiry() {
        let later = Date(timeIntervalSinceNow: 60 * 60 * 24 * 10)
        let earlier = Date(timeIntervalSinceNow: 60 * 60 * 24)
        let info = StoreState.aggregatedEntitlement(from: [
            makeTransaction("com.coffic.netto.monthly", type: .nonRenewable, expirationDate: later),
            makeTransaction("com.coffic.netto.annual", type: .nonRenewable, expirationDate: earlier)
        ])
        #expect(info.tier == .pro)
        #expect(info.expiresAt == later)
    }

    @Test("nonConsumable：不授予任何订阅权益")
    func nonConsumableGrantsNothing() {
        let info = StoreState.aggregatedEntitlement(from: [
            makeTransaction(
                "nonconsumable.car",
                type: .nonConsumable,
                expirationDate: Date(timeIntervalSinceNow: 3600)
            )
        ])
        #expect(info.tier == .none)
        #expect(info.expiresAt == nil)
    }

    @Test("consumable：不授予任何订阅权益")
    func consumableGrantsNothing() {
        let info = StoreState.aggregatedEntitlement(from: [
            makeTransaction(
                "consumable.fuel.octane87",
                type: .consumable,
                expirationDate: Date(timeIntervalSinceNow: 3600)
            )
        ])
        #expect(info.tier == .none)
        #expect(info.expiresAt == nil)
    }

    @Test("未知等级的产品 ID：等级回退 none")
    func unknownProductIDFallsBackToNone() {
        let info = StoreState.aggregatedEntitlement(from: [
            makeTransaction("com.example.unknown", type: .autoRenewable, expirationDate: Date(timeIntervalSince1970: 1_800_000_000))
        ])
        #expect(info.tier == .none)
        #expect(info.expiresAt == Date(timeIntervalSince1970: 1_800_000_000))
    }
}

/// `PluginStore` 商品快照映射内核的单测。
///
/// ## 可达性说明
/// 拉取商品依赖真实 App Store 会话，单元测试进程不可达；生产实现已把
/// 「商品分组 → 中立快照」的映射内核抽为 `PluginStore.productSnapshots(from:)`，
/// 本文件直接覆盖该内核。
@Suite("PluginStore 商品快照映射")
@MainActor
struct PluginStoreProductSnapshotTests {

    private func makeProduct(
        _ id: String,
        name: String = "商品",
        price: String = "¥1",
        kind: ProductDTO.ProductKind = .nonConsumable,
        groupID: String? = nil
    ) -> ProductDTO {
        let subscription: SubscriptionInfoDTO? = groupID.map {
            SubscriptionInfoDTO(
                subscriptionPeriod: StoreSubscriptionPeriodDTO(value: 1, unit: "month"),
                hasIntroductoryOffer: false,
                promotionalOffersCount: 0,
                introductoryOffer: nil,
                groupDisplayName: "Pro",
                groupID: $0
            )
        }
        return ProductDTO(
            id: id,
            displayName: name,
            displayPrice: price,
            price: Decimal(1),
            kind: kind,
            subscription: subscription,
            description: ""
        )
    }

    @Test("空分组：返回空快照列表")
    func emptyGroupsYieldEmptySnapshots() {
        let groups = ProductGroupsDTO(cars: [], subscriptionGroups: [], nonRenewables: [], fuel: [])
        #expect(PluginStore.productSnapshots(from: groups).isEmpty)
    }

    @Test("一次性解锁/非续订/消耗型：按 cars→nonRenewables→fuel 顺序输出且标记为非订阅")
    func nonSubscriptionProductsKeepOrder() {
        let groups = ProductGroupsDTO(
            cars: [makeProduct("nonconsumable.car", name: "Car")],
            subscriptionGroups: [],
            nonRenewables: [makeProduct("nonRenewing.standard", name: "Standard", kind: .nonRenewable)],
            fuel: [makeProduct("consumable.fuel.octane87", name: "Fuel", kind: .consumable)]
        )

        let snapshots = PluginStore.productSnapshots(from: groups)
        #expect(snapshots.map(\.id) == ["nonconsumable.car", "nonRenewing.standard", "consumable.fuel.octane87"])
        #expect(snapshots.map(\.isSubscription) == [false, false, false])
        #expect(snapshots.map(\.displayName) == ["Car", "Standard", "Fuel"])
        #expect(snapshots.map(\.price) == ["¥1", "¥1", "¥1"])
    }

    @Test("订阅组：输出为订阅快照并按组内顺序排列")
    func subscriptionGroupProductsAreMarkedAsSubscription() {
        let group = SubscriptionGroupDTO(
            name: "Pro",
            id: "20000001",
            subscriptions: [
                makeProduct("com.coffic.netto.monthly", name: "Pro Monthly", kind: .autoRenewable, groupID: "20000001"),
                makeProduct("com.coffic.netto.annual", name: "Pro Annual", kind: .autoRenewable, groupID: "20000001")
            ]
        )
        let groups = ProductGroupsDTO(cars: [], subscriptionGroups: [group], nonRenewables: [], fuel: [])

        let snapshots = PluginStore.productSnapshots(from: groups)
        #expect(snapshots.map(\.id) == ["com.coffic.netto.monthly", "com.coffic.netto.annual"])
        #expect(snapshots.map(\.isSubscription) == [true, true])
        #expect(snapshots.map(\.tier) == [.pro, .pro])
    }

    @Test("未知产品 ID：等级回退 none")
    func unknownProductIDFallsBackToNoneTier() {
        let groups = ProductGroupsDTO(
            cars: [makeProduct("com.example.unknown")],
            subscriptionGroups: [],
            nonRenewables: [],
            fuel: []
        )
        let snapshots = PluginStore.productSnapshots(from: groups)
        #expect(snapshots.count == 1)
        #expect(snapshots[0].tier == .none)
    }

    @Test("非订阅与订阅混合：订阅快照排在最后")
    func subscriptionsComeLast() {
        let group = SubscriptionGroupDTO(
            name: "Pro",
            id: "20000001",
            subscriptions: [makeProduct("com.coffic.netto.monthly", kind: .autoRenewable, groupID: "20000001")]
        )
        let groups = ProductGroupsDTO(
            cars: [makeProduct("nonconsumable.car")],
            subscriptionGroups: [group],
            nonRenewables: [],
            fuel: []
        )
        let snapshots = PluginStore.productSnapshots(from: groups)
        #expect(snapshots.map(\.id) == ["nonconsumable.car", "com.coffic.netto.monthly"])
        #expect(snapshots.map(\.isSubscription) == [false, true])
    }
}
