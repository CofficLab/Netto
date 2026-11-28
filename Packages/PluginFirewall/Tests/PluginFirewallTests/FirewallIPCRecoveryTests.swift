import Foundation
import ProviderFirewall
import XCTest
@testable import PluginFirewall

/// IPC 连接断开后的恢复行为测试。
///
/// 覆盖 issue #13：注册成功后连接失效/中断时必须重新关联扩展，
/// 否则扩展侧无 App 连接会放行一切流量（静默 fail-open）。
@MainActor
final class FirewallIPCRecoveryTests: XCTestCase {

    /// 轮询等待条件成立。
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

    // MARK: - 连接令牌登记

    func testRegisteredConnectionLossIsReportedOnce() {
        let registry = IPCConnectionRegistry()
        let token = registry.beginRegistration()
        registry.markRegistered(token)

        XCTAssertTrue(registry.consumeUnexpectedLoss(token))
        // 同一次断开只应上报一次。
        XCTAssertFalse(registry.consumeUnexpectedLoss(token))
    }

    func testLossBeforeRegistrationSucceedsIsNotReported() {
        let registry = IPCConnectionRegistry()
        let token = registry.beginRegistration()

        XCTAssertFalse(registry.consumeUnexpectedLoss(token))
    }

    func testExplicitUnregisterIsNotReportedAsUnexpectedLoss() {
        let registry = IPCConnectionRegistry()
        let token = registry.beginRegistration()
        registry.markRegistered(token)

        registry.clearAll()

        XCTAssertFalse(registry.consumeUnexpectedLoss(token))
    }

    func testSupersededConnectionLossIsNotReported() {
        let registry = IPCConnectionRegistry()
        let old = registry.beginRegistration()
        registry.markRegistered(old)

        let new = registry.beginRegistration()
        registry.markRegistered(new)

        // 旧连接被替换后失效不算意外断开。
        XCTAssertFalse(registry.consumeUnexpectedLoss(old))
        XCTAssertTrue(registry.consumeUnexpectedLoss(new))
    }

    func testCancelledRegistrationIsNotReported() {
        let registry = IPCConnectionRegistry()
        let token = registry.beginRegistration()
        registry.markRegistered(token)

        registry.cancel(token)

        XCTAssertFalse(registry.consumeUnexpectedLoss(token))
    }

    // MARK: - 控制器恢复流程

    func testConnectionLossTriggersReRegistration() async throws {
        let (controller, system, ipc, _, _) = makeController()
        // 只有过滤器启用（扩展会话存活）时，连接丢失才需要重连。
        system.filterEnabled = true
        await controller.startDaemon()
        XCTAssertEqual(ipc.registerCount, 1)

        ipc.simulateConnectionLoss()

        try await waitUntil { ipc.registerCount == 2 }
        XCTAssertEqual(ipc.registerCount, 2)
    }

    func testConnectionLossKeepsFirewallRunningAfterSuccessfulReconnect() async throws {
        let (controller, system, ipc, _, _) = makeController()
        system.filterEnabled = true
        await controller.startDaemon()
        await controller.refresh()
        XCTAssertEqual(controller.snapshot.state, .running)

        ipc.simulateConnectionLoss()

        try await waitUntil { ipc.registerCount == 2 }
        try await waitUntil { controller.snapshot.state == .running }
        XCTAssertEqual(controller.snapshot.state, .running)
    }

    func testRepeatedReconnectFailureMarksIPCDisconnected() async throws {
        let (controller, system, ipc, _, _) = makeController()
        system.filterEnabled = true
        await controller.startDaemon()
        await controller.refresh()
        XCTAssertEqual(controller.snapshot.state, .running)
        XCTAssertTrue(controller.snapshot.isIPCConnected)

        ipc.registerResult = false
        ipc.simulateConnectionLoss()

        try await waitUntil { controller.snapshot.isIPCConnected == false }
        // 重连失败只标记连接断开，不篡改过滤器状态：配置仍是启用的，
        // 界面据此展示「连接中断」而非「过滤器未生效」。
        XCTAssertEqual(controller.snapshot.state, .running)
        XCTAssertTrue(controller.snapshot.isFilterResponding)
    }

    func testRefreshReconnectsIPCWhenDisconnected() async throws {
        let (controller, system, ipc, _, _) = makeController()
        system.filterEnabled = true
        await controller.startDaemon()

        ipc.registerResult = false
        ipc.simulateConnectionLoss()

        // 等恢复流程用尽全部重试（1 次启动注册 + 3 次重连）。
        try await waitUntil { ipc.registerCount >= 4 }
        try await waitUntil { controller.snapshot.isIPCConnected == false }

        // 端点恢复后点「重新检测」即可自愈，无需重启 App。
        ipc.registerResult = true
        await controller.refresh()
        XCTAssertTrue(controller.snapshot.isIPCConnected)
    }

    func testShutdownClearsConnectionLossHandler() async throws {
        let (controller, _, ipc, _, _) = makeController()
        await controller.startDaemon()
        XCTAssertEqual(ipc.registerCount, 1)

        controller.shutdown()

        ipc.simulateConnectionLoss()
        try await Task.sleep(for: .milliseconds(200))

        XCTAssertEqual(ipc.registerCount, 1)
    }

    // MARK: - 装配辅助

    private func makeController() -> (FirewallController, MockSystemAdapter, MockIPCAdapter, MockSettings, MockEvents) {
        let system = MockSystemAdapter()
        let ipc = MockIPCAdapter()
        let settings = MockSettings()
        let events = MockEvents()
        let controller = FirewallController(system: system, ipc: ipc, settings: settings, events: events)
        return (controller, system, ipc, settings, events)
    }
}
