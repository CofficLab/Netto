import Foundation
import ProviderFirewall
import XCTest
@testable import PluginFirewall

/// 修复过滤器配置，以及「运行中但过滤器未生效」的健康判定。
///
/// 背景：Dev / TestFlight 签名切换后，系统过滤器配置仍绑定旧的
/// DataProvider 签名要求，扩展启动被拒；配置里 `isEnabled == true`，
/// 但没有任何流量到达扩展。
@MainActor
final class FirewallRepairAndHealthTests: XCTestCase {

    private func makeController() -> (FirewallController, MockSystemAdapter) {
        let system = MockSystemAdapter()
        let controller = FirewallController(
            system: system,
            ipc: MockIPCAdapter(),
            settings: MockSettings(),
            events: MockEvents()
        )
        return (controller, system)
    }

    // MARK: - 修复过滤器

    func testRepairRemovesAndRebuildsFilterAndReenables() async throws {
        let (controller, system) = makeController()
        system.filterEnabled = true
        await controller.refresh()
        XCTAssertEqual(controller.snapshot.state, .running)

        try await controller.repairFilter()

        XCTAssertEqual(system.removeCount, 1)
        XCTAssertEqual(system.installCount, 1)
        XCTAssertEqual(system.enableCount, 1)
        XCTAssertEqual(controller.snapshot.state, .running)
    }

    func testRepairRemoveFailureSurfacesFailedState() async {
        let (controller, system) = makeController()
        system.removeError = NSError(
            domain: "NEFilterManager",
            code: 5,
            userInfo: [NSLocalizedDescriptionKey: "删除失败"]
        )

        do {
            try await controller.repairFilter()
            XCTFail("期望抛出错误")
        } catch {
            guard case .failed(let failure) = controller.snapshot.state else {
                return XCTFail("期望 failed 状态")
            }
            XCTAssertEqual(failure.domain, "NEFilterManager")
        }
        XCTAssertEqual(system.installCount, 0)
    }

    func testRepairInstallFailureMapsToApprovalNeeded() async {
        let (controller, system) = makeController()
        system.installError = NSError(
            domain: "NEConfigurationErrorDomain",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "授权失败"]
        )

        do {
            try await controller.repairFilter()
            XCTFail("期望抛出错误")
        } catch {
            XCTAssertEqual(controller.snapshot.state, .filterApprovalNeeded)
        }
        XCTAssertEqual(system.enableCount, 0)
    }

    // MARK: - 健康判定（扩展心跳）

    func testMissingHeartbeatMarksFilterUnresponsiveAfterGracePeriod() async {
        let (controller, system) = makeController()
        system.filterEnabled = true
        await controller.refresh()
        XCTAssertEqual(controller.snapshot.state, .running)
        XCTAssertTrue(controller.snapshot.isFilterResponding)

        // 刚启用：扩展会话建立需要时间，宽限期内不做判定。
        controller.evaluateFilterHealth(now: Date().addingTimeInterval(5))
        XCTAssertTrue(controller.snapshot.isFilterResponding)

        // 超过宽限期仍无心跳：配置说运行中，实际未生效。
        controller.evaluateFilterHealth(now: Date().addingTimeInterval(30))
        XCTAssertFalse(controller.snapshot.isFilterResponding)
    }

    func testRecentHeartbeatKeepsFilterResponding() async {
        let (controller, system) = makeController()
        system.filterEnabled = true
        await controller.refresh()

        let now = Date()
        controller.noteExtensionHeartbeat(at: now)
        controller.evaluateFilterHealth(now: now.addingTimeInterval(10))
        XCTAssertTrue(controller.snapshot.isFilterResponding)
    }

    func testHeartbeatRecoversAfterTimeout() async {
        let (controller, system) = makeController()
        system.filterEnabled = true
        await controller.refresh()

        let now = Date()
        controller.evaluateFilterHealth(now: now.addingTimeInterval(30))
        XCTAssertFalse(controller.snapshot.isFilterResponding)

        // 心跳恢复（扩展会话重新起来）：健康标记即时恢复。
        controller.noteExtensionHeartbeat(at: now.addingTimeInterval(31))
        XCTAssertTrue(controller.snapshot.isFilterResponding)
    }

    func testRepairResetsHealthTracking() async throws {
        let (controller, system) = makeController()
        system.filterEnabled = true
        await controller.refresh()
        controller.evaluateFilterHealth(now: Date().addingTimeInterval(30))
        XCTAssertFalse(controller.snapshot.isFilterResponding)

        try await controller.repairFilter()

        XCTAssertEqual(controller.snapshot.state, .running)
        XCTAssertTrue(controller.snapshot.isFilterResponding)
    }
}