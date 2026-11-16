import Foundation
import KitStoreKit
import ProviderStore
import StoreKit
import Testing
@testable import PluginStore

/// Netto 侧「机制结果 → 权益快照」翻译的单测。
///
/// ## 可达性说明
/// 交易聚合内核由共享的 `KitStoreKit` 承担
/// （`StoreKitSubscriptionAggregator`，另有完整单测）。Netto 这一侧只负责
/// 把机制结论翻译成权益快照，翻译依赖 **Netto 商品表** 的档位映射，
/// 因此本文件覆盖「商品表 × 机制结论」的组合语义。
@Suite("Netto 权益翻译")
struct NettoEntitlementTranslationTests {

    /// 构造一个共享机制层的订阅持有结论。
    private func holding(
        productIDs: [String],
        expiration: Date?
    ) -> StoreKitSubscriptionHolding {
        StoreKitSubscriptionHolding(
            activeSubscriptionProductIDs: productIDs,
            latestExpiration: expiration
        )
    }

    @Test("空持有：无档位、无到期时间")
    func emptyHoldingYieldsFreeTier() {
        let snapshot = NettoStoreCatalog.shared.entitlement(
            activeProductIDs: holding(productIDs: [], expiration: nil).activeSubscriptionProductIDs,
            latestExpiration: nil
        )

        #expect(snapshot.tier == .none)
        #expect(snapshot.expiresAt == nil)
    }

    @Test("已登记的订阅商品：授予 Pro 档位并带上到期时间")
    func registeredProductGrantsProTier() {
        let expiry = Date(timeIntervalSince1970: 1_800_000_000)
        let snapshot = NettoStoreCatalog.shared.entitlement(
            activeProductIDs: holding(
                productIDs: ["com.coffic.netto.monthly"],
                expiration: expiry
            ).activeSubscriptionProductIDs,
            latestExpiration: expiry
        )

        #expect(snapshot.tier == .pro)
        #expect(snapshot.expiresAt == expiry)
    }

    @Test("未登记的商品 ID：档位回退 none")
    func unknownProductIDFallsBackToNone() {
        let expiry = Date(timeIntervalSince1970: 1_800_000_000)
        let snapshot = NettoStoreCatalog.shared.entitlement(
            activeProductIDs: holding(
                productIDs: ["com.example.unknown"],
                expiration: expiry
            ).activeSubscriptionProductIDs,
            latestExpiration: expiry
        )

        #expect(snapshot.tier == .none)
        #expect(snapshot.expiresAt == nil)
    }

    @Test("一次性解锁与消耗品不进入有效订阅列表")
    func nonSubscriptionProductsAreNotActive() {
        // 机制层只把订阅类商品计入有效订阅。
        let holding = StoreKitSubscriptionAggregator.aggregate(
            transactions: [
                StoreKitTransactionSummary(
                    productID: "nonconsumable.car",
                    productType: .nonConsumable,
                    expirationDate: Date(timeIntervalSinceNow: 3600),
                    purchaseDate: Date()
                ),
                StoreKitTransactionSummary(
                    productID: "consumable.fuel.octane87",
                    productType: .consumable,
                    expirationDate: Date(timeIntervalSinceNow: 3600),
                    purchaseDate: Date()
                ),
            ]
        )

        #expect(!holding.hasActiveSubscription)
    }

    @Test("过期交易不计入有效订阅")
    func expiredTransactionIsNotActive() {
        let holding = StoreKitSubscriptionAggregator.aggregate(
            transactions: [
                StoreKitTransactionSummary(
                    productID: "com.coffic.netto.monthly",
                    productType: .autoRenewable,
                    expirationDate: Date(timeIntervalSinceNow: -3600),
                    purchaseDate: Date()
                ),
            ]
        )

        #expect(!holding.hasActiveSubscription)
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
            nonRenewables: [makeProduct("nonrenewing.standard", name: "Standard", kind: .nonRenewable)],
            fuel: [makeProduct("consumable.fuel.octane87", name: "Fuel", kind: .consumable)]
        )

        let snapshots = PluginStore.productSnapshots(from: groups)
        #expect(snapshots.map(\.id) == ["nonconsumable.car", "nonrenewing.standard", "consumable.fuel.octane87"])
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
