import Foundation
import XCTest
@testable import KernelCore

// MARK: - 测试用 Mock 类型

/// 测试用中立 Provider 契约。
protocol GreetingProviding: Sendable {
    func greeting() -> String
}

/// Mock Provider 实现。
struct MockGreetingProvider: GreetingProviding {
    let text: String
    func greeting() -> String { text }
}

/// 记录生命周期调用顺序的 Mock 插件。
@MainActor
class MockPlugin: SuperPlugin {
    let id: String
    var order: Int
    var dependencies: [String]
    let metadata: PluginMetadata
    /// 共享调用记录（线程安全由测试串行保证）。
    let log: MockLifecycleLog
    /// onBoot 是否抛错。
    var bootError: Error?
    /// onReady 是否抛错。
    var readyError: Error?
    /// onShutdown 是否抛错。
    var shutdownError: Error?
    /// 是否在 onBoot 中注册 GreetingProviding。
    var registerGreetingProvider = false
    /// 注册的贡献 Token。
    var tokenToRegister: ContributionToken?
    /// 异步阶段延迟（秒）。
    var bootDelay: Duration = .zero
    /// 是否实现异步生命周期。
    let asyncLifecycle: Bool

    init(
        id: String,
        order: Int = 200,
        dependencies: [String] = [],
        policy: PluginEnablePolicy = .enabledByDefault,
        log: MockLifecycleLog,
        asyncLifecycle: Bool = false
    ) {
        self.id = id
        self.order = order
        self.dependencies = dependencies
        self.metadata = PluginMetadata(name: id, version: "1.0", policy: policy, summary: nil)
        self.log = log
        self.asyncLifecycle = asyncLifecycle
    }

    func onRegister(kernel: KernelCoreContainer) throws {
        log.events.append("register:\(id)")
    }

    func onBoot(kernel: KernelCoreContainer) throws {
        log.events.append("boot:\(id)")
        if registerGreetingProvider {
            try kernel.registerProvider(MockGreetingProvider(text: "provider-\(id)"), for: GreetingProviding.self, owner: id)
        }
        if let tokenToRegister {
            kernel.registerContribution(tokenToRegister, owner: id)
        }
        if let bootError { throw bootError }
    }

    func onReady(kernel: KernelCoreContainer) throws {
        log.events.append("ready:\(id)")
        if let readyError { throw readyError }
    }

    func onShutdown(kernel: KernelCoreContainer) throws {
        log.events.append("shutdown:\(id)")
        if let shutdownError { throw shutdownError }
    }

    func onUnregister(kernel: KernelCoreContainer) throws {
        log.events.append("unregister:\(id)")
    }

    func onEnable(kernel: KernelCoreContainer) async throws {
        log.events.append("enable:\(id)")
    }

    func onDisable(kernel: KernelCoreContainer) async throws {
        log.events.append("disable:\(id)")
    }
}

/// 实现 AsyncSuperPlugin 的 Mock。
@MainActor
final class AsyncMockPlugin: MockPlugin, AsyncSuperPlugin {
    func onBootAsync(kernel: KernelCoreContainer) async throws {
        log.events.append("bootAsync:\(id)")
        if bootDelay > .zero {
            try await Task.sleep(for: bootDelay)
        }
        if let bootError { throw bootError }
    }

    func onReadyAsync(kernel: KernelCoreContainer) async throws {
        log.events.append("readyAsync:\(id)")
    }

    func onShutdownAsync(kernel: KernelCoreContainer) async throws {
        log.events.append("shutdownAsync:\(id)")
    }
}

/// 生命周期调用顺序记录器。
@MainActor
final class MockLifecycleLog {
    var events: [String] = []
}

/// 记录 revoke 调用的贡献 Token 辅助。
@MainActor
final class TokenFactory {
    var revokedIDs: [String] = []
    func makeToken(id: String) -> ContributionToken {
        ContributionToken(id: id) { [weak self] in
            // Kernel 只在 MainActor 生命周期路径调用 revoke；同步记录保证断言确定性。
            MainActor.assumeIsolated {
                self?.revokedIDs.append(id)
            }
        }
    }
}

// MARK: - KernelCoreTests

@MainActor
final class KernelCoreTests: XCTestCase {

    private func makeKernel() -> KernelCoreContainer {
        KernelCoreContainer()
    }

    // MARK: 重复 ID / 缺失依赖 / 依赖环

    func testDuplicatePluginIDRejected() throws {
        let kernel = makeKernel()
        let log = MockLifecycleLog()
        let a1 = MockPlugin(id: "A", log: log)
        let a2 = MockPlugin(id: "A", log: log)
        XCTAssertThrowsError(try kernel.start(plugins: [a1, a2])) { error in
            XCTAssertEqual(error as? KernelCoreError, .pluginAlreadyRegistered(id: "A"))
        }
    }

    func testMissingDependencyRejected() throws {
        let kernel = makeKernel()
        let log = MockLifecycleLog()
        let b = MockPlugin(id: "B", dependencies: ["Nope"], log: log)
        XCTAssertThrowsError(try kernel.start(plugins: [b])) { error in
            XCTAssertEqual(
                error as? KernelCoreError,
                .pluginDependencyMissing(pluginID: "B", dependencyID: "Nope")
            )
        }
        XCTAssertEqual(kernel.registeredPluginCount, 0)
    }

    func testDependencyCycleRejected() throws {
        let kernel = makeKernel()
        let log = MockLifecycleLog()
        let a = MockPlugin(id: "A", dependencies: ["B"], log: log)
        let b = MockPlugin(id: "B", dependencies: ["A"], log: log)
        XCTAssertThrowsError(try kernel.start(plugins: [a, b])) { error in
            guard case .pluginDependencyCycle = error as? KernelCoreError else {
                return XCTFail("期望依赖环错误，得到 \(error)")
            }
        }
    }

    // MARK: 排序

    func testDependencySortingStable() throws {
        let kernel = makeKernel()
        let log = MockLifecycleLog()
        // order 相同但 B 依赖 A：依赖优先于 order；无依赖时按数组顺序稳定。
        let a = MockPlugin(id: "A", order: 20, log: log)
        let b = MockPlugin(id: "B", order: 20, dependencies: ["A"], log: log)
        let c = MockPlugin(id: "C", order: 10, log: log)
        try kernel.start(plugins: [a, b, c])
        // C(order 10) → A(order 20) → B(依赖 A)
        XCTAssertEqual(
            log.events.filter { $0.hasPrefix("boot:") },
            ["boot:C", "boot:A", "boot:B"]
        )
        XCTAssertEqual(kernel.lifecycleState, .running)
    }

    // MARK: 回滚

    func testBootFailureRollsBackInReverse() throws {
        let kernel = makeKernel()
        let log = MockLifecycleLog()
        let tokenFactory = TokenFactory()
        let a = MockPlugin(id: "A", order: 10, log: log)
        a.registerGreetingProvider = true
        a.tokenToRegister = tokenFactory.makeToken(id: "token-a")
        let failing = MockPlugin(id: "B", order: 20, log: log)
        failing.bootError = NSError(domain: "test", code: 1)

        XCTAssertThrowsError(try kernel.start(plugins: [a, failing]))
        // A 已 Boot 并注册贡献/Provider；B 在 register 后 Boot 失败（"boot:B"
        // 事件先于抛错记录），按 Lumi 语义仍给 B 一次 Shutdown 清理机会，
        // 然后逆序清理 A。
        XCTAssertEqual(
            log.events,
            ["register:A", "boot:A", "register:B", "boot:B", "shutdown:B", "shutdown:A", "unregister:A", "unregister:B"]
        )
        XCTAssertEqual(kernel.registeredPluginCount, 0)
        XCTAssertEqual(kernel.registeredProviderCount, 0)
        XCTAssertEqual(kernel.contributionCount(ownedBy: "A"), 0)
        XCTAssertEqual(kernel.lifecycleState, .failed)
        // 回滚完成后 Token 应已撤回。
        XCTAssertEqual(tokenFactory.revokedIDs, ["token-a"])
    }

    func testReadyFailureRollsBack() throws {
        let kernel = makeKernel()
        let log = MockLifecycleLog()
        let a = MockPlugin(id: "A", order: 10, log: log)
        a.registerGreetingProvider = true
        let failing = MockPlugin(id: "B", order: 20, log: log)
        failing.readyError = NSError(domain: "test", code: 2)

        XCTAssertThrowsError(try kernel.start(plugins: [a, failing]))
        XCTAssertEqual(
            log.events,
            ["register:A", "boot:A", "register:B", "boot:B", "ready:A", "ready:B", "shutdown:B", "shutdown:A", "unregister:A", "unregister:B"]
        )
        XCTAssertEqual(kernel.registeredPluginCount, 0)
        XCTAssertEqual(kernel.registeredProviderCount, 0)
    }

    func testShutdownReverseOrderAndContributionsRevoked() throws {
        let kernel = makeKernel()
        let log = MockLifecycleLog()
        let tokenFactory = TokenFactory()
        let a = MockPlugin(id: "A", order: 10, log: log)
        a.registerGreetingProvider = true
        a.tokenToRegister = tokenFactory.makeToken(id: "token-a")
        let b = MockPlugin(id: "B", order: 20, dependencies: ["A"], log: log)

        try kernel.start(plugins: [a, b])
        XCTAssertEqual(kernel.registeredProviderCount, 1)

        try kernel.stop()
        XCTAssertEqual(
            log.events,
            [
                "register:A", "boot:A", "register:B", "boot:B", "ready:A", "ready:B",
                "shutdown:B", "shutdown:A", "unregister:B", "unregister:A",
            ]
        )
        XCTAssertEqual(kernel.registeredPluginCount, 0)
        XCTAssertEqual(kernel.registeredProviderCount, 0)
        XCTAssertEqual(kernel.lifecycleState, .stopped)
        XCTAssertEqual(tokenFactory.revokedIDs, ["token-a"])
    }

    // MARK: Provider 语义

    func testProviderResolveReturnsNilWhenMissing() throws {
        let kernel = makeKernel()
        // 缺失 Provider 明确返回 nil，不做强制解包。
        let resolved: GreetingProviding? = kernel.resolveProvider(GreetingProviding.self)
        XCTAssertNil(resolved)
        XCTAssertThrowsError(try kernel.requireProvider(GreetingProviding.self)) { error in
            XCTAssertEqual(
                error as? KernelCoreError,
                .providerNotFound(type: String(describing: GreetingProviding.self))
            )
        }
    }

    func testDuplicateProviderRejected() throws {
        let kernel = makeKernel()
        try kernel.registerProvider(MockGreetingProvider(text: "a"), for: GreetingProviding.self, owner: "A")
        XCTAssertThrowsError(
            try kernel.registerProvider(MockGreetingProvider(text: "b"), for: GreetingProviding.self, owner: "B")
        ) { error in
            XCTAssertEqual(
                error as? KernelCoreError,
                .providerAlreadyRegistered(type: String(describing: GreetingProviding.self))
            )
        }
    }

    // MARK: disable / enable

    func testDisableRevokesProviderAndContributionEnableRestores() async throws {
        let kernel = makeKernel()
        let log = MockLifecycleLog()
        let tokenFactory = TokenFactory()
        let a = MockPlugin(id: "A", order: 10, log: log)
        a.registerGreetingProvider = true
        a.tokenToRegister = tokenFactory.makeToken(id: "token-a")
        try kernel.start(plugins: [a])
        XCTAssertNotNil(kernel.resolveProvider(GreetingProviding.self))

        try await kernel.disablePlugin(id: "A")
        XCTAssertNil(kernel.resolveProvider(GreetingProviding.self))
        XCTAssertEqual(kernel.contributionCount(ownedBy: "A"), 0)
        XCTAssertEqual(tokenFactory.revokedIDs, ["token-a"])
        XCTAssertFalse(kernel.isPluginEnabled(id: "A"))
        XCTAssertEqual(log.events.filter { $0 == "disable:A" }, ["disable:A"])

        try await kernel.enablePlugin(id: "A")
        // onEnable 不重新注册 Provider（插件的 onEnable 负责恢复自己的资源）。
        XCTAssertTrue(kernel.isPluginEnabled(id: "A"))
        XCTAssertEqual(log.events.filter { $0 == "enable:A" }, ["enable:A"])
    }

    // MARK: 异步生命周期

    func testAsyncBootTimeoutRollsBack() async throws {
        let kernel = makeKernel()
        kernel.asyncPhaseTimeout = .milliseconds(200)
        let log = MockLifecycleLog()
        let slow = AsyncMockPlugin(id: "Slow", log: log, asyncLifecycle: true)
        slow.bootDelay = .seconds(2)

        do {
            try await kernel.startAsync(plugins: [slow])
            XCTFail("期望超时错误")
        } catch let error as KernelCoreError {
            XCTAssertEqual(error, .asyncPhaseTimeout(pluginID: "Slow", phase: "boot"))
        }
        XCTAssertEqual(kernel.lifecycleState, .failed)
        XCTAssertEqual(kernel.registeredPluginCount, 0)
        // 超时后 Slow 仍有一次清理（unregister）。
        XCTAssertTrue(log.events.contains("unregister:Slow"))
    }

    func testAsyncBootCancellationRollsBack() async throws {
        let kernel = makeKernel()
        let log = MockLifecycleLog()
        let slow = AsyncMockPlugin(id: "Slow", log: log, asyncLifecycle: true)
        slow.bootDelay = .seconds(10)

        let task = Task {
            try await kernel.startAsync(plugins: [slow])
        }
        // 取消宿主 Task。
        task.cancel()
        do {
            try await task.value
            XCTFail("期望取消错误")
        } catch {
            // CancellationError 或 asyncPhaseCancelled 均可接受；关键是干净回滚。
        }
        XCTAssertEqual(kernel.registeredPluginCount, 0)
        XCTAssertEqual(kernel.registeredProviderCount, 0)
    }

    func testAsyncLifecycleHappyPath() async throws {
        let kernel = makeKernel()
        let log = MockLifecycleLog()
        let a = AsyncMockPlugin(id: "A", order: 10, log: log, asyncLifecycle: true)
        let b = AsyncMockPlugin(id: "B", order: 20, dependencies: ["A"], log: log, asyncLifecycle: true)
        try await kernel.startAsync(plugins: [a, b])
        XCTAssertEqual(kernel.lifecycleState, .running)
        XCTAssertEqual(
            log.events,
            [
                "register:A", "bootAsync:A", "register:B", "bootAsync:B",
                "readyAsync:A", "readyAsync:B",
            ]
        )
        try await kernel.stopAsync()
        XCTAssertEqual(
            log.events.filter { $0.hasPrefix("shutdownAsync:") },
            ["shutdownAsync:B", "shutdownAsync:A"]
        )
        XCTAssertEqual(kernel.registeredPluginCount, 0)
        XCTAssertEqual(kernel.lifecycleState, .stopped)
    }

    // MARK: 非法重入

    func testInvalidLifecycleReentryRejected() throws {
        let kernel = makeKernel()
        let log = MockLifecycleLog()
        let a = MockPlugin(id: "A", log: log)
        try kernel.start(plugins: [a])
        // running 状态下重复 start 同批插件：依赖/重复校验先行，抛重复 ID 错误。
        XCTAssertThrowsError(try kernel.start(plugins: [a])) { error in
            XCTAssertEqual(error as? KernelCoreError, .pluginAlreadyRegistered(id: "A"))
        }
        try kernel.stop()
        // stopped 状态下再 stop 是幂等 no-op（与 Lumi 语义一致），不抛错。
        try kernel.stop()
        XCTAssertEqual(kernel.lifecycleState, .stopped)
    }

    func testUnloadPluginRejectedWhileDependent() throws {
        let kernel = makeKernel()
        let log = MockLifecycleLog()
        let a = MockPlugin(id: "A", order: 10, log: log)
        let b = MockPlugin(id: "B", order: 20, dependencies: ["A"], log: log)
        try kernel.start(plugins: [a, b])
        XCTAssertThrowsError(try kernel.unloadPlugin(id: "A")) { error in
            guard case .invalidLifecycleOperation = error as? KernelCoreError else {
                return XCTFail("期望非法生命周期错误，得到 \(error)")
            }
        }
        // 卸载 B 成功。
        try kernel.unloadPlugin(id: "B")
        XCTAssertFalse(kernel.isPluginRegistered(id: "B"))
        XCTAssertTrue(kernel.isPluginRegistered(id: "A"))
    }

    // MARK: 策略

    func testDisabledPolicyPluginNotRegistered() throws {
        let kernel = makeKernel()
        let log = MockLifecycleLog()
        let off = MockPlugin(id: "Off", policy: .disabled, log: log)
        try kernel.start(plugins: [off])
        XCTAssertFalse(kernel.isPluginRegistered(id: "Off"))
        XCTAssertEqual(kernel.registeredPluginCount, 0)
        XCTAssertEqual(log.events, [])
    }

    func testRequiredPolicyAlwaysEnabled() throws {
        let kernel = makeKernel()
        let log = MockLifecycleLog()
        let required = MockPlugin(id: "Req", policy: .required, log: log)
        try kernel.start(plugins: [required])
        XCTAssertTrue(kernel.isPluginEnabled(id: "Req"))
        XCTAssertEqual(kernel.lifecycleState, .running)
    }
}
