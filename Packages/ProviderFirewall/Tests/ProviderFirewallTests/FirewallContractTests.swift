import Foundation
import XCTest
@testable import ProviderFirewall

/// 契约类型行为测试：Sendable/Equatable 值语义、状态推导、失败信息保留。
final class FirewallContractTests: XCTestCase {

    func testSnapshotDerivesCanStartAndCanStop() {
        let running = FirewallSnapshot(state: .running)
        XCTAssertTrue(running.canStop)
        XCTAssertFalse(running.canStart)

        let stopped = FirewallSnapshot(state: .stopped)
        XCTAssertTrue(stopped.canStart)
        XCTAssertFalse(stopped.canStop)
    }

    func testDistinctStatesNotMerged() {
        // 安装审批/未激活/未安装/Applications 目录等状态必须保持可区分，
        // 与旧 FilterStatus 全量语义一一对应，不得合并为 stopped。
        let states: [FirewallState] = [
            .stopped, .running, .installing, .waitingForApproval,
            .systemExtensionApprovalNeeded, .filterApprovalNeeded,
            .disabled, .extensionNotActivated,
            .systemExtensionNotInstalled, .systemExtensionNeedsUpdate,
            .filterNotInstalled, .notInApplicationsFolder, .permissionDenied,
        ]
        XCTAssertEqual(Set(states).count, states.count)
    }

    func testNewStatesCanStartSemantics() {
        // 旧 FilterStatus.canStart：stopped/indeterminate/disabled 可启动。
        XCTAssertTrue(FirewallState.stopped.canStart)
        XCTAssertTrue(FirewallState.unknown.canStart)
        XCTAssertTrue(FirewallState.disabled.canStart)
        XCTAssertFalse(FirewallState.extensionNotActivated.canStart)
        XCTAssertFalse(FirewallState.systemExtensionApprovalNeeded.canStart)
        XCTAssertFalse(FirewallState.systemExtensionNeedsUpdate.canStart)
    }

    func testFailureKeepsFullErrorInformation() {
        let failure = FirewallFailure(domain: "NetworkExtension", code: -1001, message: "激活失败: 用户拒绝")
        XCTAssertEqual(failure.domain, "NetworkExtension")
        XCTAssertEqual(failure.code, -1001)
        XCTAssertEqual(failure.message, "激活失败: 用户拒绝")
        // 失败状态携带完整信息，不降级为 stopped。
        let state = FirewallState.failed(failure)
        XCTAssertEqual(state, .failed(failure))
        XCTAssertNotEqual(state, .stopped)
    }

    func testSnapshotEquatableValueSemantics() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let a = FirewallSnapshot(state: .running, lastUpdated: date)
        let b = FirewallSnapshot(state: .running, lastUpdated: date)
        XCTAssertEqual(a, b)
    }
}
