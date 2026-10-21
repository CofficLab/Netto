import Foundation
import XCTest
@testable import ProviderFirewallEvents

/// 查询与维护结果值类型的构造与语义测试。
///
/// 既有 `FirewallEventsContractTests` 覆盖分页边界与决策存储值，
/// 本文件补齐三个查询/结果值类型的初始化路径与默认值语义。
final class FirewallEventValueTypeTests: XCTestCase {

    // MARK: - FirewallEventQuery

    func testQueryDefaults() {
        let query = FirewallEventQuery()

        XCTAssertNil(query.appIdentifier)
        XCTAssertNil(query.status)
        XCTAssertNil(query.direction)
        XCTAssertEqual(query.page, 0)
        XCTAssertEqual(query.pageSize, 50)
    }

    func testQueryKeepsExplicitValues() {
        let query = FirewallEventQuery(
            appIdentifier: "com.app",
            status: .rejected,
            direction: .inbound,
            page: 3,
            pageSize: 20
        )

        XCTAssertEqual(query.appIdentifier, "com.app")
        XCTAssertEqual(query.status, .rejected)
        XCTAssertEqual(query.direction, .inbound)
        XCTAssertEqual(query.page, 3)
        XCTAssertEqual(query.pageSize, 20)
    }

    func testQueryIsMutableValueType() {
        var query = FirewallEventQuery()
        query.appIdentifier = "com.other"
        query.status = .allowed
        query.direction = .outbound
        query.page = 1
        query.pageSize = 10

        XCTAssertEqual(query.appIdentifier, "com.other")
        XCTAssertEqual(query.status, .allowed)
        XCTAssertEqual(query.direction, .outbound)
        XCTAssertEqual(query.page, 1)
        XCTAssertEqual(query.pageSize, 10)

        // 值语义：副本与原值互不影响。
        let copy = query
        query.page = 9
        XCTAssertEqual(copy.page, 1)
        XCTAssertEqual(query.page, 9)
    }

    // MARK: - FirewallEventCountQuery

    func testCountQueryDefaults() {
        let query = FirewallEventCountQuery()

        XCTAssertNil(query.appIdentifier)
        XCTAssertNil(query.status)
        XCTAssertNil(query.direction)
    }

    func testCountQueryKeepsExplicitValues() {
        let query = FirewallEventCountQuery(
            appIdentifier: "com.app",
            status: .allowed,
            direction: .outbound
        )

        XCTAssertEqual(query.appIdentifier, "com.app")
        XCTAssertEqual(query.status, .allowed)
        XCTAssertEqual(query.direction, .outbound)
    }

    func testCountQueryIsMutableValueType() {
        var query = FirewallEventCountQuery()
        query.appIdentifier = "com.app"

        XCTAssertEqual(query.appIdentifier, "com.app")
    }

    // MARK: - FirewallMaintenanceResult

    func testMaintenanceResultDefaults() {
        let result = FirewallMaintenanceResult()

        XCTAssertEqual(result.deletedEventCount, 0)
        XCTAssertFalse(result.isDatabaseHealthy)
        XCTAssertEqual(result.executionTime, 0)
        XCTAssertFalse(result.isSuccessful)
        XCTAssertNil(result.errorMessage)
    }

    func testMaintenanceResultKeepsExplicitValues() {
        let result = FirewallMaintenanceResult(
            deletedEventCount: 42,
            isDatabaseHealthy: true,
            executionTime: 1.5,
            isSuccessful: true,
            errorMessage: nil
        )

        XCTAssertEqual(result.deletedEventCount, 42)
        XCTAssertTrue(result.isDatabaseHealthy)
        XCTAssertEqual(result.executionTime, 1.5)
        XCTAssertTrue(result.isSuccessful)
        XCTAssertNil(result.errorMessage)
    }

    func testMaintenanceResultCarriesErrorMessage() {
        let result = FirewallMaintenanceResult(
            deletedEventCount: 0,
            isDatabaseHealthy: false,
            executionTime: 0.25,
            isSuccessful: false,
            errorMessage: "数据库被占用"
        )

        XCTAssertEqual(result.errorMessage, "数据库被占用")
        XCTAssertFalse(result.isSuccessful)
    }

    func testMaintenanceResultIsMutableValueType() {
        var result = FirewallMaintenanceResult()
        result.deletedEventCount = 7
        result.isDatabaseHealthy = true
        result.executionTime = 2
        result.isSuccessful = true

        XCTAssertEqual(result.deletedEventCount, 7)
        XCTAssertTrue(result.isDatabaseHealthy)
        XCTAssertEqual(result.executionTime, 2)
        XCTAssertTrue(result.isSuccessful)
    }

    // MARK: - 枚举与变更通知

    func testDecisionAllCasesAndStorageRawValues() {
        XCTAssertEqual(FirewallEventDecision.allCases, [.allowed, .rejected])
        XCTAssertEqual(FirewallEventDecision.allowed.storageRawValue, 0)
        XCTAssertEqual(FirewallEventDecision.rejected.storageRawValue, 1)
    }

    func testTrafficDirectionAllCases() {
        XCTAssertEqual(FirewallTrafficDirection.allCases, [.inbound, .outbound])
    }

    func testEventChangeVariants() {
        let event = makeEvent(id: "e1")

        XCTAssertEqual(FirewallEventChange.created(event), .created(event))
        XCTAssertEqual(FirewallEventChange.deleted(eventID: "e1"), .deleted(eventID: "e1"))
        XCTAssertNotEqual(FirewallEventChange.deleted(eventID: "e1"), .deleted(eventID: "e2"))
        XCTAssertEqual(FirewallEventChange.cleared, .cleared)
    }

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
}
