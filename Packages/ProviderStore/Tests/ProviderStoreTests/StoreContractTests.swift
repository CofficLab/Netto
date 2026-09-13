import Foundation
import XCTest
@testable import ProviderStore

/// 契约值类型测试：等级比较、权益过期/生效等级。
final class StoreContractTests: XCTestCase {

    func testTierComparison() {
        XCTAssertTrue(StoreTier.none < .pro)
        XCTAssertTrue(StoreTier.pro < .ultimate)
        XCTAssertTrue(StoreTier.pro.isProOrHigher)
        XCTAssertTrue(StoreTier.ultimate.isUltimateOrHigher)
        XCTAssertFalse(StoreTier.none.isProOrHigher)
    }

    func testEntitlementExpiryAndEffectiveTier() {
        let active = StoreEntitlementSnapshot(tier: .pro, expiresAt: Date().addingTimeInterval(3600))
        XCTAssertTrue(active.isProOrHigher)
        XCTAssertEqual(active.effectiveTier, .pro)

        let expired = StoreEntitlementSnapshot(tier: .pro, expiresAt: Date().addingTimeInterval(-7200))
        XCTAssertFalse(expired.isProOrHigher)
        XCTAssertEqual(expired.effectiveTier, .none)

        let nilExpiry = StoreEntitlementSnapshot(tier: .pro, expiresAt: nil)
        XCTAssertFalse(nilExpiry.isProOrHigher)
        XCTAssertEqual(StoreEntitlementSnapshot.none.tier, .none)
    }

    func testProductSnapshotValueSemantics() {
        let a = StoreProductSnapshot(id: "com.coffic.netto.monthly", displayName: "月度", price: "¥18", tier: .pro, isSubscription: true)
        let b = StoreProductSnapshot(id: "com.coffic.netto.monthly", displayName: "月度", price: "¥18", tier: .pro, isSubscription: true)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.id, "com.coffic.netto.monthly")
    }
}
