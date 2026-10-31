import Foundation
import ProviderStore
import Testing
@testable import ProviderStoreKit

/// Netto 商店能力契约的测试。
///
/// 契约本身是纯协议，测试聚焦于「实现方能以共享契约的类型满足契约」这一
/// 集成点——共享层的 `StoreTier` / `StoreEntitlementSnapshot` 与 Netto 的
/// `StoreProviding` 必须对齐，否则消费方拿到的权益结论会失真。
@Suite("ProviderStoreKit")
@MainActor
struct ProviderStoreKitTests {

    /// 满足 Netto 商店契约的最小实现。
    private final class StubStore: StoreProviding {
        var entitlement: StoreEntitlementSnapshot
        private(set) var restored = false

        init(entitlement: StoreEntitlementSnapshot = .none) {
            self.entitlement = entitlement
        }

        func loadProducts() async throws -> [StoreProductSnapshot] { [] }

        func purchase(_ productID: String) async throws {}

        func restore() async throws {
            restored = true
        }

        func observeEntitlement() -> AsyncStream<StoreEntitlementSnapshot> {
            AsyncStream { $0.finish() }
        }
    }

    /// 实现方可以直接用共享契约的权益快照。
    @Test
    func providerUsesSharedEntitlementSnapshot() {
        let snapshot = StoreEntitlementSnapshot(
            tier: .pro,
            expiresAt: Date().addingTimeInterval(3600)
        )
        let provider = StubStore(entitlement: snapshot)

        #expect(provider.entitlement == snapshot)
        #expect(provider.entitlement.tier == .pro)
        #expect(provider.entitlement.isProOrHigher)
    }

    /// 过期快照的生效档位是免费档。
    @Test
    func expiredSnapshotYieldsFreeTier() {
        let provider = StubStore(
            entitlement: StoreEntitlementSnapshot(
                tier: .pro,
                expiresAt: Date().addingTimeInterval(-3600)
            )
        )

        #expect(provider.entitlement.tier == .pro)
        #expect(provider.entitlement.effectiveTier == .none)
        #expect(!provider.entitlement.isProOrHigher)
    }

    /// 空权益是免费档。
    @Test
    func noneSnapshotYieldsFreeTier() {
        let provider = StubStore()

        #expect(provider.entitlement == .none)
        #expect(provider.entitlement.effectiveTier == .none)
    }
}
