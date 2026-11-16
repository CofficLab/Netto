import Foundation
import StoreKit
import Testing
@testable import PluginStore

/// `StoreService` 的纯逻辑与错误路径测试。
///
/// ## 可达性说明
/// StoreKit 2 的 `Product` / `Transaction` / `Product.SubscriptionInfo` 均没有公开
/// initializer，单元测试进程无法构造；`Product.products(for:)` 在 SwiftPM 测试包
/// （非签名 App）里会直接抛 `StoreKitInternalError.invalidApp`（已实测）。
/// 因此所有依赖真实 App Store 会话或真实交易对象的分支在本包单测中不可达，
/// 这里只覆盖「不依赖交易对象」的纯逻辑与错误路径。
@Suite("StoreService 逻辑")
struct StoreServiceLogicTests {

    // MARK: - checkVerified

    @Test("checkVerified：验证通过时原样返回载荷")
    func checkVerifiedReturnsPayload() throws {
        let result: VerificationResult<String> = .verified("payload")
        let value = try StoreService.checkVerified(result)
        #expect(value == "payload")
    }

    @Test("checkVerified：未验证时抛出 failedVerification")
    func checkVerifiedThrowsForUnverified() {
        let result: VerificationResult<String> = .unverified("payload", .invalidSignature)
        #expect(throws: StoreError.failedVerification) {
            try StoreService.checkVerified(result)
        }
    }

    // MARK: - tier

    @Test("tier(for:)：按产品 ID 返回订阅等级，未知 ID 回退 none")
    func tierMapping() {
        #expect(StoreService.tier(for: "com.coffic.netto.monthly") == .pro)
        #expect(StoreService.tier(for: "com.coffic.netto.annual") == .pro)
        #expect(StoreService.tier(for: "nonconsumable.car") == .none)
        #expect(StoreService.tier(for: "com.example.unknown") == .none)
    }

    // MARK: - computeExpirationDate

    @Test("computeExpirationDate：状态为 nil 时返回 distantPast")
    func computeExpirationDateForNilStatus() {
        let date = StoreService.computeExpirationDate(from: nil)
        #expect(date == Date.distantPast)
    }

    // MARK: - 依赖 App Store 的入口（单测进程内抛 invalidApp）

    @Test("fetchAllProducts：SwiftPM 测试进程内无有效 App，抛错而非返回空列表")
    func fetchAllProductsThrows() async {
        await #expect(throws: (any Error).self) {
            _ = try await StoreService.fetchAllProducts()
        }
    }

    @Test("fetchAllSubscriptionGroups：与 fetchAllProducts 同样抛错")
    func fetchAllSubscriptionGroupsThrows() async {
        await #expect(throws: (any Error).self) {
            _ = try await StoreService.fetchAllSubscriptionGroups()
        }
    }

    @Test("purchase(productID:)：取不到商品时抛错（StoreKit 先于 canNotGetProducts 失败）")
    func purchaseByIDThrows() async {
        await #expect(throws: (any Error).self) {
            _ = try await StoreService.purchase(productID: "com.coffic.netto.monthly")
        }
    }

    @Test("purchase(ProductDTO)：同样在取商品阶段抛错")
    func purchaseByDTOThrows() async {
        let dto = ProductDTO(
            id: "com.coffic.netto.monthly",
            displayName: "Pro Monthly",
            displayPrice: "¥18",
            price: Decimal(18),
            kind: .autoRenewable,
            description: ""
        )
        await #expect(throws: (any Error).self) {
            _ = try await StoreService.purchase(dto)
        }
    }

    // MARK: - fetchPurchasedLists

    @Test("fetchPurchasedLists：单测进程无权益，返回三个空清单")
    func fetchPurchasedListsIsEmptyWithoutEntitlements() async {
        let car = ProductDTO(
            id: "nonconsumable.car",
            displayName: "Car",
            displayPrice: "¥99",
            price: Decimal(99),
            kind: .nonConsumable,
            description: ""
        )
        let subscription = ProductDTO(
            id: "com.coffic.netto.monthly",
            displayName: "Pro Monthly",
            displayPrice: "¥18",
            price: Decimal(18),
            kind: .autoRenewable,
            description: ""
        )
        let result = await StoreService.fetchPurchasedLists(
            cars: [car],
            subscriptions: [subscription],
            nonRenewables: []
        )
        #expect(result.cars.isEmpty)
        #expect(result.subscriptions.isEmpty)
        #expect(result.nonRenewables.isEmpty)
    }

    // MARK: - 交易监听

    @Test("observeTransactionUpdates：可被取消，不会挂起测试进程")
    func observeTransactionUpdatesIsCancellable() async {
        let task = Task { await StoreService.observeTransactionUpdates() }
        // 让监听循环有机会进入 for-await，再取消。
        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()
        // 兜底：最多等 2 秒，避免 StoreKit 行为异常时测试挂死。
        await withTaskGroup(of: Void.self) { group in
            group.addTask { _ = try? await task.value }
            group.addTask {
                try? await Task.sleep(for: .seconds(2))
            }
            _ = await group.next()
            group.cancelAll()
        }
    }
}

/// `StoreError` 的错误描述测试。
@Suite("StoreError")
struct StoreErrorTests {

    @Test("failedVerification 使用英文错误码作为描述")
    func failedVerificationDescription() {
        #expect(StoreError.failedVerification.errorDescription == "failedVerification")
    }

    @Test("canNotGetProducts 使用中文错误描述")
    func canNotGetProductsDescription() {
        #expect(StoreError.canNotGetProducts.errorDescription == "发生错误：无法获取产品")
    }
}
