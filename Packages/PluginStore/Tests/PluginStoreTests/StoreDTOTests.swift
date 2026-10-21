import Foundation
import StoreKit
import Testing
@testable import PluginStore

/// `ProductDTO` / `ProductGroupsDTO` / 订阅 DTO 的值语义测试。
///
/// ## 可达性说明
/// `ProductDTO.toDTO(_:kind:)`、`ProductGroupsDTO.init(products:)` 等入口的入参是
/// StoreKit `Product`，在单元测试进程里不可构造，故这些映射分支不可达。
/// 纯 DTO 组装/分组/查询逻辑在此覆盖。
@Suite("Store DTO")
struct StoreDTOTests {

    // MARK: - ProductDTO

    @Test("ProductDTO：初始化保存全部字段")
    func productDTOInit() {
        let subscription = SubscriptionInfoDTO(
            subscriptionPeriod: StoreSubscriptionPeriodDTO(value: 1, unit: "month"),
            hasIntroductoryOffer: false,
            promotionalOffersCount: 0,
            introductoryOffer: nil,
            groupDisplayName: "Pro",
            groupID: "20000001"
        )
        let dto = ProductDTO(
            id: "com.coffic.netto.monthly",
            displayName: "Pro Monthly",
            displayPrice: "¥18",
            price: Decimal(string: "18.00") ?? Decimal(18),
            kind: .autoRenewable,
            subscription: subscription,
            description: "月度订阅"
        )

        #expect(dto.id == "com.coffic.netto.monthly")
        #expect(dto.displayName == "Pro Monthly")
        #expect(dto.displayPrice == "¥18")
        #expect(dto.price == Decimal(string: "18.00") ?? Decimal(18))
        #expect(dto.kind == .autoRenewable)
        #expect(dto.description == "月度订阅")
        #expect(dto.subscription?.groupID == "20000001")
    }

    @Test("ProductDTO：subscription 缺省为 nil，description 可变")
    func productDTOWithoutSubscription() {
        let dto = ProductDTO(
            id: "nonconsumable.car",
            displayName: "Car",
            displayPrice: "¥99",
            price: Decimal(99),
            kind: .nonConsumable,
            description: "一次性解锁"
        )
        #expect(dto.subscription == nil)

        var mutable = dto
        mutable.description = "改过的描述"
        #expect(mutable.description == "改过的描述")
        // 原始值类型不受影响（struct 值语义）。
        #expect(dto.description == "一次性解锁")
    }

    @Test("ProductDTO：同类字段完全相同时 Hashable/Equatable 成立")
    func productDTOEquality() {
        let make: () -> ProductDTO = {
            ProductDTO(
                id: "fuel",
                displayName: "Fuel",
                displayPrice: "¥1",
                price: Decimal(1),
                kind: .consumable,
                description: "燃料"
            )
        }
        #expect(make() == make())
        #expect(make().hashValue == make().hashValue)
    }

    @Test("ProductDTO.ProductKind：全部原始值可解码")
    func productKindRawValues() {
        #expect(ProductDTO.ProductKind.consumable.rawValue == "consumable")
        #expect(ProductDTO.ProductKind.nonConsumable.rawValue == "nonConsumable")
        #expect(ProductDTO.ProductKind.autoRenewable.rawValue == "autoRenewable")
        #expect(ProductDTO.ProductKind.nonRenewable.rawValue == "nonRenewable")
        #expect(ProductDTO.ProductKind.unknown.rawValue == "unknown")
    }

    // MARK: - ProductGroupsDTO

    @Test("ProductGroupsDTO：按分组初始化保留各分组内容")
    func productGroupsDTOInitByGroup() {
        let car = makeProduct(id: "nonconsumable.car", kind: .nonConsumable)
        let nonRenewable = makeProduct(id: "nonRenewing.standard", kind: .nonRenewable)
        let fuel = makeProduct(id: "consumable.fuel.octane87", kind: .consumable)
        let group = SubscriptionGroupDTO(
            name: "Pro",
            id: "20000001",
            subscriptions: [makeProduct(id: "com.coffic.netto.monthly", kind: .autoRenewable)]
        )

        let groups = ProductGroupsDTO(
            cars: [car],
            subscriptionGroups: [group],
            nonRenewables: [nonRenewable],
            fuel: [fuel]
        )

        #expect(groups.cars.map(\.id) == ["nonconsumable.car"])
        #expect(groups.nonRenewables.map(\.id) == ["nonRenewing.standard"])
        #expect(groups.fuel.map(\.id) == ["consumable.fuel.octane87"])
        #expect(groups.subscriptionGroups.count == 1)
        #expect(groups.subscriptionGroups.first?.name == "Pro")
    }

    @Test("ProductGroupsDTO.subscriptions：扁平化所有订阅组")
    func flattenedSubscriptions() {
        let groupA = SubscriptionGroupDTO(
            name: "Pro",
            id: "20000001",
            subscriptions: [makeProduct(id: "com.coffic.netto.monthly", kind: .autoRenewable)]
        )
        let groupB = SubscriptionGroupDTO(
            name: "Ultimate",
            id: "20000002",
            subscriptions: [makeProduct(id: "com.coffic.ultimate.monthly", kind: .autoRenewable)]
        )
        let groups = ProductGroupsDTO(
            cars: [],
            subscriptionGroups: [groupA, groupB],
            nonRenewables: [],
            fuel: []
        )

        #expect(groups.subscriptions.map(\.id) == ["com.coffic.netto.monthly", "com.coffic.ultimate.monthly"])
    }

    @Test("ProductGroupsDTO.subscriptionGroup(withId:)：命中返回组，未命中返回 nil")
    func subscriptionGroupLookup() {
        let group = SubscriptionGroupDTO(
            name: "Pro",
            id: "20000001",
            subscriptions: [makeProduct(id: "com.coffic.netto.monthly", kind: .autoRenewable)]
        )
        let groups = ProductGroupsDTO(
            cars: [],
            subscriptionGroups: [group],
            nonRenewables: [],
            fuel: []
        )

        #expect(groups.subscriptionGroup(withId: "20000001")?.name == "Pro")
        #expect(groups.subscriptionGroup(withId: "missing") == nil)
    }

    // MARK: - createSubscriptionGroups

    @Test("createSubscriptionGroups：按订阅组 ID 聚合并按价格升序排列")
    func createSubscriptionGroupsAggregatesAndSorts() {
        let monthly = makeProduct(
            id: "com.coffic.netto.monthly",
            kind: .autoRenewable,
            price: Decimal(18),
            groupID: "20000001",
            groupName: "Pro"
        )
        let annual = makeProduct(
            id: "com.coffic.netto.annual",
            kind: .autoRenewable,
            price: Decimal(168),
            groupID: "20000001",
            groupName: "Pro"
        )

        let groups = ProductGroupsDTO.createSubscriptionGroups(from: [annual, monthly])

        #expect(groups.count == 1)
        let group = groups[0]
        #expect(group.id == "20000001")
        #expect(group.name == "Pro")
        // 价格从低到高。
        #expect(group.subscriptions.map(\.id) == ["com.coffic.netto.monthly", "com.coffic.netto.annual"])
    }

    @Test("createSubscriptionGroups：不同组 ID 拆成多个订阅组")
    func createSubscriptionGroupsSplitsByGroupID() {
        let pro = makeProduct(
            id: "com.coffic.netto.monthly",
            kind: .autoRenewable,
            price: Decimal(18),
            groupID: "20000001",
            groupName: "Pro"
        )
        let ultimate = makeProduct(
            id: "com.coffic.ultimate.monthly",
            kind: .autoRenewable,
            price: Decimal(38),
            groupID: "20000002",
            groupName: "Ultimate"
        )

        let groups = ProductGroupsDTO.createSubscriptionGroups(from: [pro, ultimate])

        #expect(groups.count == 2)
        #expect(Set(groups.map(\.id)) == ["20000001", "20000002"])
    }

    @Test("createSubscriptionGroups：缺少订阅信息时归入 unknown 组")
    func createSubscriptionGroupsFallsBackToUnknownGroup() {
        // 没有 subscription 信息的自动续费商品 → groupID 回退为 "unknown"。
        let orphan = makeProduct(id: "com.coffic.netto.orphan", kind: .autoRenewable, groupID: nil)

        let groups = ProductGroupsDTO.createSubscriptionGroups(from: [orphan])

        #expect(groups.count == 1)
        #expect(groups[0].id == "unknown")
        // 组名回退为组 ID。
        #expect(groups[0].name == "unknown")
    }

    @Test("createSubscriptionGroups：组显示名缺失时回退为组 ID")
    func createSubscriptionGroupsFallsBackToGroupIDAsName() {
        let product = makeProduct(
            id: "com.coffic.netto.monthly",
            kind: .autoRenewable,
            groupID: "20000001",
            groupName: nil
        )

        let groups = ProductGroupsDTO.createSubscriptionGroups(from: [product])

        #expect(groups.count == 1)
        #expect(groups[0].id == "20000001")
        #expect(groups[0].name == "20000001")
    }

    @Test("createSubscriptionGroups：空输入返回空数组")
    func createSubscriptionGroupsWithEmptyInput() {
        #expect(ProductGroupsDTO.createSubscriptionGroups(from: []).isEmpty)
    }

    // MARK: - category(for:)

    @Test("category：StoreKit 商品类型映射到 DTO 分类")
    func categoryMapping() {
        #expect(ProductGroupsDTO.category(for: .consumable) == .consumable)
        #expect(ProductGroupsDTO.category(for: .nonConsumable) == .nonConsumable)
        #expect(ProductGroupsDTO.category(for: .autoRenewable) == .autoRenewable)
        #expect(ProductGroupsDTO.category(for: .nonRenewable) == .nonRenewable)
    }

    @Test("category：未知商品类型回退 unknown")
    func categoryFallsBackToUnknown() {
        // 构造一个 StoreKit 未定义的商品类型，覆盖 default 分支。
        let unknown = Product.ProductType(rawValue: "futureType")
        #expect(ProductGroupsDTO.category(for: unknown) == .unknown)
    }

    // MARK: - 订阅 DTO

    @Test("SubscriptionInfoDTO：status 缺省为空数组")
    func subscriptionInfoDTODefaultStatus() {
        let info = SubscriptionInfoDTO(
            subscriptionPeriod: StoreSubscriptionPeriodDTO(value: 1, unit: "month"),
            hasIntroductoryOffer: false,
            promotionalOffersCount: 0,
            introductoryOffer: nil,
            groupDisplayName: "Pro",
            groupID: "20000001"
        )
        #expect(info.status.isEmpty)
        #expect(info.hasIntroductoryOffer == false)
        #expect(info.promotionalOffersCount == 0)
        #expect(info.introductoryOffer == nil)
        #expect(info.groupDisplayName == "Pro")
        #expect(info.groupID == "20000001")
    }

    @Test("IntroductoryOfferDTO：保存优惠展示信息")
    func introductoryOfferDTO() {
        let offer = IntroductoryOfferDTO(
            displayPrice: "¥0",
            numberOfPeriods: 1,
            paymentMode: "free",
            subscriptionPeriod: StoreSubscriptionPeriodDTO(value: 1, unit: "week")
        )
        #expect(offer.displayPrice == "¥0")
        #expect(offer.numberOfPeriods == 1)
        #expect(offer.paymentMode == "free")
        #expect(offer.subscriptionPeriod.unit == "week")
    }

    @Test("StoreSubscriptionPeriodDTO：Codable 往返保持数值")
    func subscriptionPeriodDTOIsCodable() throws {
        let period = StoreSubscriptionPeriodDTO(value: 12, unit: "month")
        let data = try JSONEncoder().encode(period)
        let decoded = try JSONDecoder().decode(StoreSubscriptionPeriodDTO.self, from: data)
        #expect(decoded == period)
    }

    @Test("SubscriptionPeriod.Unit：已知单位映射为英文名称")
    func subscriptionPeriodUnitDescription() {
        #expect(Product.SubscriptionPeriod.Unit.day.description == "day")
        #expect(Product.SubscriptionPeriod.Unit.week.description == "week")
        #expect(Product.SubscriptionPeriod.Unit.month.description == "month")
        #expect(Product.SubscriptionPeriod.Unit.year.description == "year")
    }

    @Test("SubscriptionGroupDTO：保存组名/组 ID/订阅列表")
    func subscriptionGroupDTO() {
        let group = SubscriptionGroupDTO(
            name: "Pro",
            id: "20000001",
            subscriptions: [makeProduct(id: "com.coffic.netto.monthly", kind: .autoRenewable)]
        )
        #expect(group.name == "Pro")
        #expect(group.id == "20000001")
        #expect(group.subscriptions.count == 1)
    }

    // MARK: - Helper

    private func makeProduct(
        id: String,
        kind: ProductDTO.ProductKind,
        price: Decimal = Decimal(10),
        groupID: String? = "20000001",
        groupName: String? = "Pro"
    ) -> ProductDTO {
        let subscriptionInfo: SubscriptionInfoDTO? = {
            guard kind == .autoRenewable, let groupID else { return nil }
            return SubscriptionInfoDTO(
                subscriptionPeriod: StoreSubscriptionPeriodDTO(value: 1, unit: "month"),
                hasIntroductoryOffer: false,
                promotionalOffersCount: 0,
                introductoryOffer: nil,
                groupDisplayName: groupName ?? groupID,
                groupID: groupID
            )
        }()

        return ProductDTO(
            id: id,
            displayName: id,
            displayPrice: "¥\(price)",
            price: price,
            kind: kind,
            subscription: subscriptionInfo,
            description: ""
        )
    }
}
