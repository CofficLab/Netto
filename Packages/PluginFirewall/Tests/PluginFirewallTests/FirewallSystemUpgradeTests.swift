import Foundation
import ProviderFirewall
import SystemExtensions
import XCTest
@testable import PluginFirewall

/// 系统扩展版本替换流程与 CFBundleVersion 比较。
///
/// 背景：过滤器运行期间替换扩展，系统会重建 NetworkExtension 的
/// launchd 任务，扩展的 Mach service 端点可能丢失，之后 App 永远连不上
/// 扩展（界面显示运行中，实际无法决策）。替换前必须先停过滤器。
@MainActor
final class FirewallSystemUpgradeTests: XCTestCase {

    private func waitUntil(
        timeout: TimeInterval = 5,
        _ condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTFail("等待条件超时")
    }

    private func makeController() -> (FirewallController, MockSystemAdapter, MockIPCAdapter) {
        let system = MockSystemAdapter()
        let ipc = MockIPCAdapter()
        let controller = FirewallController(
            system: system,
            ipc: ipc,
            settings: MockSettings(),
            events: MockEvents()
        )
        return (controller, system, ipc)
    }

    private func newerProperty(version: String = "2.0") -> SystemExtensionPropertyInfo {
        SystemExtensionPropertyInfo(
            bundleIdentifier: "ext",
            bundleVersion: version,
            bundleShortVersion: version,
            urlPath: "/x",
            isEnabled: true,
            isAwaitingUserApproval: false,
            isUninstalling: false
        )
    }

    // MARK: - 升级流程

    func testUpgradeWhileRunningStopsFilterBeforeActivating() async throws {
        let (controller, system, _) = makeController()
        system.filterEnabled = true
        await controller.refresh()
        XCTAssertEqual(controller.snapshot.state, .running)

        controller.systemExtensionProperties([newerProperty()])

        XCTAssertEqual(controller.snapshot.state, .systemExtensionNeedsUpdate)
        try await waitUntil {
            system.disableCount == 1 && system.submittedRequests.last == .activate
        }
        XCTAssertFalse(system.filterEnabled, "替换扩展前必须先停用过滤器")
    }

    func testUpgradeResumesFilterAndRebuildsIPCOnActivation() async throws {
        let (controller, system, ipc) = makeController()
        system.filterEnabled = true
        await controller.refresh()

        controller.systemExtensionProperties([newerProperty()])
        // 等停用与激活请求都发出，确保 pendingFilterResume 已置位。
        try await waitUntil {
            system.disableCount == 1 && system.submittedRequests.last == .activate
        }

        controller.systemExtensionActivationCompleted()

        try await waitUntil { system.enableCount == 1 && controller.snapshot.state == .running }
        XCTAssertTrue(system.filterEnabled)
        XCTAssertTrue(controller.snapshot.isIPCConnected)
        XCTAssertEqual(ipc.registerCount, 1, "激活替换了扩展进程，必须重新关联 IPC")
    }

    func testUpgradeFailureRestoresFilter() async throws {
        let (controller, system, _) = makeController()
        system.filterEnabled = true
        await controller.refresh()

        controller.systemExtensionProperties([newerProperty()])
        try await waitUntil {
            system.disableCount == 1 && system.submittedRequests.last == .activate
        }

        controller.systemExtensionRequestFailed(
            NSError(domain: "SystemExtensions", code: 1, userInfo: [NSLocalizedDescriptionKey: "升级失败"])
        )

        // 升级失败不能留下无防护状态：旧过滤器必须恢复启用。
        try await waitUntil { system.enableCount == 1 }
        XCTAssertTrue(system.filterEnabled)
        XCTAssertEqual(controller.snapshot.state, .running)
    }

    func testFailedUpgradeIsNotRetriedAutomatically() async throws {
        let (controller, system, _) = makeController()
        system.filterEnabled = true
        await controller.refresh()

        controller.systemExtensionProperties([newerProperty()])
        try await waitUntil {
            system.disableCount == 1 && system.submittedRequests.last == .activate
        }
        controller.systemExtensionRequestFailed(
            NSError(domain: "SystemExtensions", code: 1, userInfo: [NSLocalizedDescriptionKey: "升级失败"])
        )
        try await waitUntil { system.enableCount == 1 }

        let disableCount = system.disableCount
        // 同一版本再次上报属性：不得再次自动停过滤器/激活，否则会反复弹授权。
        controller.systemExtensionProperties([newerProperty()])
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(system.disableCount, disableCount)
        XCTAssertEqual(controller.snapshot.state, .systemExtensionNeedsUpdate)
    }

    // MARK: - 版本比较

    func testVersionComparisonIsNumeric() {
        XCTAssertTrue(FirewallController.isVersion("2.10", newerThan: "2.9"))
        XCTAssertFalse(FirewallController.isVersion("2.9", newerThan: "2.10"))
        XCTAssertTrue(FirewallController.isVersion("1.0.1", newerThan: "1.0"))
        XCTAssertFalse(FirewallController.isVersion("1.0", newerThan: "1.0.0"))
        XCTAssertTrue(FirewallController.isVersion("1.0", newerThan: ""))
        XCTAssertFalse(FirewallController.isVersion("", newerThan: ""))
    }
}