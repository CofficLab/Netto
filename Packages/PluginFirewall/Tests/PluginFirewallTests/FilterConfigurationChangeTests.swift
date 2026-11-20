import Foundation
import XCTest
@testable import PluginFirewall

/// 过滤器配置变更后的状态必须来自一次新的加载（issue #14）。
///
/// `NEFilterManager` 的属性是进程内副本：外部（在系统设置里）开关过滤器后，
/// 观察者若直接读 `isEnabled` 拿到的还是上一次的旧值，状态会判断反了。
@MainActor
final class FilterConfigurationChangeTests: XCTestCase {

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

    /// 等待条件成立（观察者回调是异步触发的）。
    private func waitUntil(
        timeout: TimeInterval = 3,
        _ condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("等待条件超时")
    }

    func testExternalDisableIsReflectedInState() async throws {
        let (controller, system) = makeController()
        system.filterEnabled = true
        controller.startObserving()
        await controller.refresh()
        XCTAssertEqual(controller.snapshot.state, .running)

        // 用户在系统设置里关掉过滤器。
        system.filterEnabled = false
        system.observerHandler?()

        try await waitUntil { controller.snapshot.state == .stopped }
        XCTAssertEqual(controller.snapshot.state, .stopped)
    }

    func testExternalEnableIsReflectedInState() async throws {
        let (controller, system) = makeController()
        controller.startObserving()
        await controller.refresh()
        XCTAssertEqual(controller.snapshot.state, .stopped)

        // 用户在系统设置里打开过滤器。
        system.filterEnabled = true
        system.observerHandler?()

        try await waitUntil { controller.snapshot.state == .running }
        XCTAssertEqual(controller.snapshot.state, .running)
    }

    func testLoadFailureAfterChangeSurfacesFailedState() async throws {
        let (controller, system) = makeController()
        controller.startObserving()

        system.loadError = NSError(
            domain: "NEFilterManager",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "读取失败"]
        )
        system.observerHandler?()

        try await waitUntil {
            if case .failed = controller.snapshot.state { return true }
            return false
        }
        guard case .failed(let failure) = controller.snapshot.state else {
            return XCTFail("期望 failed 状态")
        }
        XCTAssertEqual(failure.domain, "NEFilterManager")
    }
}
