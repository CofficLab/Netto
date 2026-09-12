import Foundation
import XCTest
@testable import ProviderFirewallEvents

/// 契约值类型测试：分页边界、决策存储值、变更通知值语义。
final class FirewallEventsContractTests: XCTestCase {

    private func makeEvent(id: String) -> FirewallEventSnapshot {
        FirewallEventSnapshot(
            id: id,
            time: Date(timeIntervalSince1970: 1_700_000_000),
            address: "example.com",
            port: "443",
            sourceAppIdentifier: "com.example.app",
            status: .allowed,
            direction: .outbound,
            appId: "com.example.app"
        )
    }

    func testDecisionStorageValuesMatchLegacySemantics() {
        XCTAssertEqual(FirewallEventDecision.allowed.storageRawValue, 0)
        XCTAssertEqual(FirewallEventDecision.rejected.storageRawValue, 1)
    }

    func testPaginationHasNextPageBoundary() {
        // 0-based 分页：pageSize=50，totalCount=100 → page1 之后没有下一页。
        let page0 = FirewallEventPage(events: [], totalCount: 100, page: 0, pageSize: 50)
        XCTAssertTrue(page0.hasNextPage)
        let page1 = FirewallEventPage(events: [], totalCount: 100, page: 1, pageSize: 50)
        XCTAssertFalse(page1.hasNextPage)
        // 空页。
        let empty = FirewallEventPage(events: [], totalCount: 0, page: 0, pageSize: 50)
        XCTAssertFalse(empty.hasNextPage)
    }

    func testSnapshotEquatableAndIdentifiable() {
        let event = makeEvent(id: "abc")
        XCTAssertEqual(event, makeEvent(id: "abc"))
        XCTAssertNotEqual(event, makeEvent(id: "def"))
        XCTAssertEqual(event.id, "abc")
    }

    func testChangePayloadCarriesSnapshotNotModel() {
        let event = makeEvent(id: "e1")
        let change = FirewallEventChange.created(event)
        guard case .created(let snapshot) = change else {
            return XCTFail("期望 created 携带 Snapshot")
        }
        XCTAssertEqual(snapshot.id, "e1")
        XCTAssertEqual(FirewallEventChange.deleted(eventID: "e1"), .deleted(eventID: "e1"))
        XCTAssertEqual(FirewallEventChange.cleared, .cleared)
    }
}
