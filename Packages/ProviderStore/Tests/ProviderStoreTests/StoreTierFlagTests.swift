import Foundation
import XCTest
@testable import ProviderStore

/// `StoreTier` 分级标记与权益快照过期语义的补充测试。
///
/// 既有 `StoreContractTests` 覆盖等级比较、权益过期与产品快照值语义；
/// 本文件补齐 `isFree` 标记与到期时间边界的细节。
final class StoreTierFlagTests: XCTestCase {

    func testIsFreeOnlyForNoneTier() {
        XCTAssertTrue(StoreTier.none.isFree)
        XCTAssertFalse(StoreTier.pro.isFree)
        XCTAssertFalse(StoreTier.ultimate.isFree)
    }

    func testIsProOrHigherAndIsUltimateOrHigherAreConsistent() {
        XCTAssertFalse(StoreTier.none.isProOrHigher)
        XCTAssertTrue(StoreTier.pro.isProOrHigher)
        XCTAssertTrue(StoreTier.ultimate.isProOrHigher)

        XCTAssertFalse(StoreTier.none.isUltimateOrHigher)
        XCTAssertFalse(StoreTier.pro.isUltimateOrHigher)
        XCTAssertTrue(StoreTier.ultimate.isUltimateOrHigher)
    }

    func testTierOrderingFollowsRawValue() {
        XCTAssertTrue(StoreTier.none < StoreTier.pro)
        XCTAssertTrue(StoreTier.pro < StoreTier.ultimate)
        XCTAssertTrue(StoreTier.none < StoreTier.ultimate)
        XCTAssertFalse(StoreTier.ultimate < StoreTier.pro)
    }
}

/// 权益快照到期时间边界的补充测试。
final class StoreEntitlementBoundaryTests: XCTestCase {

    func testNilExpiryIsExpired() {
        let snapshot = StoreEntitlementSnapshot(tier: .pro, expiresAt: nil)

        XCTAssertTrue(snapshot.isExpired)
        XCTAssertFalse(snapshot.isProOrHigher)
        XCTAssertEqual(snapshot.effectiveTier, .none)
    }

    func testFutureExpiryIsNotExpired() {
        let snapshot = StoreEntitlementSnapshot(tier: .ultimate, expiresAt: Date().addingTimeInterval(3600))

        XCTAssertFalse(snapshot.isExpired)
        XCTAssertTrue(snapshot.isProOrHigher)
        XCTAssertEqual(snapshot.effectiveTier, .ultimate)
    }

    func testPastExpiryIsExpired() {
        let snapshot = StoreEntitlementSnapshot(tier: .ultimate, expiresAt: Date().addingTimeInterval(-3600))

        XCTAssertTrue(snapshot.isExpired)
        XCTAssertFalse(snapshot.isProOrHigher)
        XCTAssertEqual(snapshot.effectiveTier, .none)
    }

    func testNoneTierNeverGrantsProEvenWhenNotExpired() {
        let snapshot = StoreEntitlementSnapshot(tier: .none, expiresAt: Date().addingTimeInterval(3600))

        XCTAssertFalse(snapshot.isExpired)
        XCTAssertFalse(snapshot.isProOrHigher)
        XCTAssertEqual(snapshot.effectiveTier, .none)
    }

    func testNoneConstantIsExpiredAndFree() {
        XCTAssertEqual(StoreEntitlementSnapshot.none.tier, .none)
        XCTAssertNil(StoreEntitlementSnapshot.none.expiresAt)
        XCTAssertTrue(StoreEntitlementSnapshot.none.isExpired)
        XCTAssertTrue(StoreEntitlementSnapshot.none.tier.isFree)
    }
}
