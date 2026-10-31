import Foundation
import ProviderStore

/// Netto 的商店能力契约。
///
/// 与共享的 `ProviderStore` 契约的分工：
/// - 共享契约（`ProviderStore`）定义**跨 App 通用的**商店语义：档位、权益快照、
///   权益能力协议、购买呈现协议；
/// - 本协议定义 **Netto 特有的**能力：加载商品、发起购买、订阅权益变更流。
///   这些是 Netto 商店窗口与其消费方（如防火墙面板）之间的应用内契约。
///
/// 本包不依赖 StoreKit：对外只暴露中立 Snapshot 与商品 ID，
/// 保证 Kernel 与其它插件不需要引入 StoreKit 依赖。
@MainActor
public protocol StoreProviding: AnyObject, Sendable {
    /// 当前权益快照。
    var entitlement: StoreEntitlementSnapshot { get }

    /// 加载全部商品。
    func loadProducts() async throws -> [StoreProductSnapshot]

    /// 发起购买。
    func purchase(_ productID: String) async throws

    /// 恢复购买。
    func restore() async throws

    /// 观察权益变化（替代 NotificationCenter 通知）。
    func observeEntitlement() -> AsyncStream<StoreEntitlementSnapshot>
}
