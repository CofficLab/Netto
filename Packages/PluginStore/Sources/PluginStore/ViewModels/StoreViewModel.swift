import Foundation
import ProviderStore
import SwiftUI

// MARK: - 商品列表状态

/// 商品列表的呈现状态。
///
/// 四种情况各自对应**用户能采取的下一步动作**：等待、重试、确认无商品、
/// 正常浏览。若都退化成一句「加载中」，用户会看到一个永远转不出来的页面。
public enum StoreProductListState: Equatable {
    /// 首次加载，尚无数据。
    case loading
    /// 加载失败且无数据。
    case error
    /// 加载成功但商店没有返回商品。
    case empty
    /// 有商品可展示。
    case content

    public static func resolve(
        isRefreshing: Bool,
        hasProducts: Bool,
        hasError: Bool
    ) -> StoreProductListState {
        if hasProducts { return .content }
        if isRefreshing { return .loading }
        if hasError { return .error }
        return .empty
    }
}

// MARK: - 加载代际

/// 加载代际策略：拒绝晚到的旧结果覆盖新结果。
///
/// 用户连续点「重试」时，两次请求的响应可能乱序返回；只接受代际等于
/// 当前代际的结果，旧响应被丢弃。
public enum StoreLoadPolicy {
    public static func shouldApplyResult(
        currentGeneration: Int,
        resultGeneration: Int
    ) -> Bool {
        resultGeneration == currentGeneration
    }
}

// MARK: - 恢复购买状态

public enum StoreRestoreState: Equatable {
    /// 尚未发起恢复。
    case idle
    /// 正在恢复。
    case restoring
    /// 恢复成功：确实新增了权益。
    case success
    /// 恢复失败。
    case failed
    /// 恢复完成，但没找到可恢复的购买。
    ///
    /// 恢复调用成功返回不代表找回了权益——免费用户同样会成功返回。
    /// 一律报「成功」会给出与事实相反的结论。
    case nothingFound
}

// MARK: - 商店状态容器

/// 商店设置页的状态容器。
///
/// 职责边界：拉商品、发起购买 / 恢复购买、汇总当前权益。StoreKit 调用
/// 全部走 `StoreService`（共享 `KitStoreKit` 机制层），本类型不直接触碰
/// StoreKit 类型。
@MainActor
public final class StoreViewModel: ObservableObject {

    // MARK: - Published State

    /// 订阅组（组内商品互为替代档位）。
    @Published private(set) var subscriptionGroups: [SubscriptionGroupDTO] = []

    /// 当前账户已购买的商品 ID 集合。
    @Published private(set) var purchasedProductIDs: Set<String> = []

    /// 是否正在加载商品。
    @Published private(set) var isLoading = false

    /// 正在购买的商品 ID。
    @Published private(set) var purchasingProductID: String?

    /// 当前权益快照。
    @Published private(set) var entitlement: StoreEntitlementSnapshot

    /// 商品加载错误（不清空已有商品，以横幅提示）。
    @Published private(set) var loadError: Error?

    /// 购买错误。
    ///
    /// 与 `loadError` 分开：购买失败不是「商品列表刷新失败」，混用会让
    /// 用户误以为商品下架。
    @Published private(set) var purchaseError: Error?

    /// 恢复购买状态。
    @Published private(set) var restoreState: StoreRestoreState = .idle

    /// 恢复购买错误。
    @Published private(set) var restoreError: Error?

    // MARK: - Private State

    private var loadGeneration = 0
    private var entitlementObserver: NSObjectProtocol?

    // MARK: - Init

    public init() {
        entitlement = StoreService.cachedPurchaseInfo()

        // 权益变更来自共享机制层的校准结果（StoreState.update 后发出）。
        entitlementObserver = NotificationCenter.default.addObserver(
            forName: .storeEntitlementUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshEntitlement()
            }
        }
    }

    /// 停止接收权益变更事件（Swift 6 的 deinit 不能访问主线程隔离属性）。
    public func dispose() {
        if let entitlementObserver {
            NotificationCenter.default.removeObserver(entitlementObserver)
        }
        entitlementObserver = nil
    }

    // MARK: - Derived State

    /// 是否为未过期的付费用户。
    public var isPro: Bool {
        entitlement.isProOrHigher
    }

    /// 档位显示名。
    ///
    /// 用生效档位（`effectiveTier`）：过期订阅回落免费档，与同一屏的
    /// 订阅状态保持一致。
    public var tierDisplayName: String {
        switch entitlement.effectiveTier {
        case .none: return "免费版"
        case .pro: return "Pro 版"
        case .ultimate: return "终极版"
        }
    }

    /// 权益到期时间。
    public var expiresAt: Date? {
        entitlement.expiresAt
    }

    /// 商品列表的呈现状态。
    public var listState: StoreProductListState {
        StoreProductListState.resolve(
            isRefreshing: isLoading,
            hasProducts: !subscriptionGroups.isEmpty,
            hasError: loadError != nil
        )
    }

    /// 某个商品是否已购买。
    public func isPurchased(_ productID: String) -> Bool {
        purchasedProductIDs.contains(productID)
    }

    // MARK: - Loading

    /// 加载商品列表；失败时保留旧数据，只记录错误。
    public func loadProducts() async {
        loadGeneration += 1
        let generation = loadGeneration

        isLoading = true

        do {
            let groups = try await StoreService.fetchAllProducts()
            let purchased = await purchasedProductIDs(in: groups)

            guard StoreLoadPolicy.shouldApplyResult(
                currentGeneration: loadGeneration,
                resultGeneration: generation
            ) else { return }

            subscriptionGroups = groups.subscriptionGroups
            purchasedProductIDs = purchased
            loadError = nil
            isLoading = false
        } catch {
            guard StoreLoadPolicy.shouldApplyResult(
                currentGeneration: loadGeneration,
                resultGeneration: generation
            ) else { return }

            loadError = error
            isLoading = false
        }
    }

    /// 读取当前账户已购买的订阅商品 ID。
    private func purchasedProductIDs(in groups: ProductGroupsDTO) async -> Set<String> {
        let purchased = await StoreService.fetchPurchasedLists(
            cars: groups.cars,
            subscriptions: groups.subscriptions,
            nonRenewables: groups.nonRenewables
        )
        return Set(purchased.subscriptions.map(\.id))
    }

    private func refreshEntitlement() {
        entitlement = StoreService.cachedPurchaseInfo()
    }

    private func refreshPurchasedProducts() async {
        guard let groups = try? await StoreService.fetchAllProducts() else { return }
        purchasedProductIDs = await purchasedProductIDs(in: groups)
    }

    // MARK: - Purchase

    /// 购买指定商品；用户取消或失败返回 `false`。
    @discardableResult
    public func purchase(_ productID: String) async -> Bool {
        guard purchasingProductID == nil else { return false }

        purchasingProductID = productID
        purchaseError = nil
        defer { purchasingProductID = nil }

        do {
            guard try await StoreService.purchase(productID: productID) != nil else {
                // 用户取消：不视为失败，也不改变已购状态。
                return false
            }

            // 购买后用全量校准纠正持有集合，再同步已购标记与权益。
            await StoreService.calibrateFromCurrentEntitlements()
            refreshEntitlement()
            await refreshPurchasedProducts()
            return true
        } catch {
            purchaseError = error
            return false
        }
    }

    // MARK: - Restore

    /// 恢复购买：比较恢复前后的持有集合判定结果。
    public func restore() async {
        guard restoreState != .restoring else { return }

        restoreState = .restoring
        restoreError = nil

        let before = purchasedProductIDs

        do {
            try await StoreService.restorePurchases()

            refreshEntitlement()
            await refreshPurchasedProducts()

            restoreState = purchasedProductIDs != before ? .success : .nothingFound

            await loadProducts()
        } catch {
            restoreError = error
            restoreState = .failed
        }
    }

    /// 重置恢复状态（供「重试」使用）。
    public func resetRestoreState() {
        restoreState = .idle
        restoreError = nil
    }
}
