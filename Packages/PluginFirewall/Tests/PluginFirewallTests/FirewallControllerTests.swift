import Foundation
import KernelCore
import NettoIPCContracts
import ProviderAppSettings
import ProviderFirewall
import ProviderFirewallEvents
import XCTest
@testable import PluginFirewall

// MARK: - Mock 适配器

/// Mock 系统适配器：脚本化过滤器状态与系统扩展属性。
@MainActor
final class MockSystemAdapter: FirewallSystemAdapting {
    var appInApplicationsFolder = true
    var currentVersion: (version: String, shortVersion: String, identifier: String)? = ("1.0", "1.0", "com.yueyi.TravelMode.Extension")
    var filterEnabled = false
    var loadError: Error?
    var installError: Error?
    var enableError: Error?
    var disableError: Error?

    private(set) var installCount = 0
    private(set) var enableCount = 0
    private(set) var disableCount = 0
    private(set) var submittedRequests: [SystemExtensionRequestKind] = []
    var observerHandler: (@MainActor @Sendable (Bool) -> Void)?
    var workspaceHandler: (@MainActor @Sendable () -> Void)?
    private(set) var workspaceRegistered = false
    private(set) var workspaceUnregistered = false

    var isAppInApplicationsFolder: Bool { appInApplicationsFolder }

    var currentExtensionVersion: (version: String, shortVersion: String, identifier: String)? { currentVersion }

    func loadFilterEnabled() async throws -> Bool {
        if let loadError { throw loadError }
        return filterEnabled
    }

    func installFilterConfiguration() async throws {
        installCount += 1
        if let installError { throw installError }
        filterEnabled = false
    }

    func enableFilter() async throws {
        enableCount += 1
        if let enableError { throw enableError }
        filterEnabled = true
    }

    func disableFilter() async throws {
        disableCount += 1
        if let disableError { throw disableError }
        filterEnabled = false
    }

    func addFilterConfigurationObserver(_ handler: @escaping @MainActor @Sendable (Bool) -> Void) -> Any {
        observerHandler = handler
        return NSObject()
    }

    func removeFilterConfigurationObserver(_ token: Any) {
        observerHandler = nil
    }

    func submitSystemExtensionRequest(_ kind: SystemExtensionRequestKind) {
        submittedRequests.append(kind)
    }

    func registerWorkspaceObserver(handler: @escaping @MainActor @Sendable () -> Void) {
        workspaceHandler = handler
        workspaceRegistered = true
    }

    func unregisterWorkspaceObserver() {
        workspaceRegistered = false
        workspaceUnregistered = true
    }
}

/// Mock IPC 适配器：记录 register/unregister。
@MainActor
final class MockIPCAdapter: FirewallIPCServing {
    var registerResult = true
    private(set) var registerCount = 0
    private(set) var unregisterCount = 0
    var exportedAppCommunication: (any AppCommunication)?

    func register() async -> Bool {
        registerCount += 1
        return registerResult
    }

    func unregister() {
        unregisterCount += 1
    }
}

/// Mock 设置：脚本化决策。
@MainActor
final class MockSettings: AppSettingsProviding {
    var allowRules: [String: Bool] = [:]

    func fetchAll() async throws -> [AppSettingSnapshot] { [] }
    func find(_ appId: String) async throws -> AppSettingSnapshot? { nil }
    func deniedApps() async throws -> [AppSettingSnapshot] { [] }
    func deniedAppsCount() async throws -> Int { 0 }

    func shouldAllow(_ appId: String) async -> Bool { allowRules[appId] ?? true }

    func shouldAllowSync(_ appId: String) -> Bool { allowRules[appId] ?? true }

    func setAllow(_ appId: String) async throws {}
    func setDeny(_ appId: String) async throws {}
    func delete(_ appId: String) async throws {}
    func observeChanges() -> AsyncStream<AppSettingsChange> { AsyncStream { _ in } }
}

/// Mock 事件存储：记录创建的快照。
@MainActor
final class MockEvents: FirewallEventsProviding {
    private(set) var created: [FirewallEventSnapshot] = []
    var createError: Error?

    func fetchPage(_ query: FirewallEventQuery) async throws -> FirewallEventPage {
        FirewallEventPage(events: [], totalCount: 0, page: query.page, pageSize: query.pageSize)
    }

    func count(_ query: FirewallEventCountQuery) async throws -> Int { 0 }
    func totalCount() async throws -> Int { 0 }
    func allAppIds() async throws -> [String] { [] }

    func fetchByTimeRange(from: Date, to: Date, appIdentifier: String?) async throws -> [ProviderFirewallEvents.FirewallEventSnapshot] { [] }
    func appIdsSince(_ date: Date) async throws -> [String] { [] }

    func create(_ event: FirewallEventSnapshot) async throws {
        if let createError { throw createError }
        created.append(event)
    }

    func deleteByAppId(_ appId: String) async throws {}
    func deleteAll() async throws -> Int { 0 }
    func cleanupOlderThan(days: Int) async throws -> Int { 0 }
    func triggerMaintenance() async throws -> FirewallMaintenanceResult { FirewallMaintenanceResult() }
    func observeChanges() -> AsyncStream<FirewallEventChange> { AsyncStream { _ in } }
}

// MARK: - 测试

/// 状态机与生命周期测试：全状态语义、操作流、决策路径、插件装配。
@MainActor
final class FirewallControllerTests: XCTestCase {

    private func makeController(
        system: MockSystemAdapter? = nil,
        ipc: MockIPCAdapter? = nil,
        settings: MockSettings? = nil,
        events: MockEvents? = nil
    ) -> (FirewallController, MockSystemAdapter, MockIPCAdapter, MockSettings, MockEvents) {
        let system = system ?? MockSystemAdapter()
        let ipc = ipc ?? MockIPCAdapter()
        let settings = settings ?? MockSettings()
        let events = events ?? MockEvents()
        let controller = FirewallController(system: system, ipc: ipc, settings: settings, events: events)
        return (controller, system, ipc, settings, events)
    }

    // MARK: - 状态推导（与旧 FilterStatus 语义对应）

    func testNotInApplicationsFolderState() async {
        let (controller, system, _, _, _) = makeController()
        system.appInApplicationsFolder = false
        await controller.installSystemExtension()
        XCTAssertEqual(controller.snapshot.state, .notInApplicationsFolder)
    }

    func testSystemExtensionNotInstalledState() async {
        let (controller, system, _, _, _) = makeController()
        // 属性回调：当前版本未安装且无其他版本。
        controller.systemExtensionProperties([])
        XCTAssertEqual(controller.snapshot.state, .systemExtensionNotInstalled)
    }

    func testSystemExtensionNeedsUpdateStateAndAutoUpgrade() async {
        let (controller, system, _, _, _) = makeController()
        let older = SystemExtensionPropertyInfo(
            bundleIdentifier: "ext", bundleVersion: "0.9", bundleShortVersion: "0.9",
            urlPath: "/x", isEnabled: true, isAwaitingUserApproval: false, isUninstalling: false
        )
        controller.systemExtensionProperties([older])
        XCTAssertEqual(controller.snapshot.state, .systemExtensionNeedsUpdate)
        // 旧行为：需更新时自动提交激活请求（静默升级）。
        XCTAssertEqual(system.submittedRequests.last, .activate)
    }

    func testExtensionNotActivatedState() async {
        let (controller, system, _, _, _) = makeController()
        let installed = SystemExtensionPropertyInfo(
            bundleIdentifier: "ext", bundleVersion: "1.0", bundleShortVersion: "1.0",
            urlPath: "/x", isEnabled: false, isAwaitingUserApproval: false, isUninstalling: false
        )
        controller.systemExtensionProperties([installed])
        XCTAssertEqual(controller.snapshot.state, .extensionNotActivated)
    }

    func testInstalledUninstallingMapsToNotInstalled() async {
        let (controller, system, _, _, _) = makeController()
        let uninstalling = SystemExtensionPropertyInfo(
            bundleIdentifier: "ext", bundleVersion: "1.0", bundleShortVersion: "1.0",
            urlPath: "/x", isEnabled: true, isAwaitingUserApproval: false, isUninstalling: true
        )
        controller.systemExtensionProperties([uninstalling])
        XCTAssertEqual(controller.snapshot.state, .systemExtensionNotInstalled)
    }

    func testNeedsUserApprovalState() async {
        let (controller, _, _, _, _) = makeController()
        controller.systemExtensionNeedsUserApproval()
        XCTAssertEqual(controller.snapshot.state, .systemExtensionApprovalNeeded)
    }

    func testRequestFailedMapsToFailedWithFullInfo() async {
        let (controller, _, _, _, _) = makeController()
        let error = NSError(domain: "SystemExtensions", code: -1, userInfo: [NSLocalizedDescriptionKey: "激活失败"])
        controller.systemExtensionRequestFailed(error)
        guard case .failed(let failure) = controller.snapshot.state else {
            return XCTFail("期望 failed 状态")
        }
        XCTAssertEqual(failure.domain, "SystemExtensions")
        XCTAssertEqual(failure.code, -1)
        XCTAssertEqual(failure.message, "激活失败")
    }

    func testActivationCompletedResetsNotReadyStatesToStopped() async {
        let (controller, _, _, _, _) = makeController()
        controller.systemExtensionProperties([])
        XCTAssertEqual(controller.snapshot.state, .systemExtensionNotInstalled)
        controller.systemExtensionActivationCompleted()
        XCTAssertEqual(controller.snapshot.state, .stopped)
    }

    // MARK: - 操作流

    func testStartWhenAlreadyEnabledOnlyUpdatesRunning() async throws {
        let (controller, system, _, _, _) = makeController()
        system.filterEnabled = true
        try await controller.start()
        XCTAssertEqual(controller.snapshot.state, .running)
        XCTAssertEqual(system.installCount, 0)
        XCTAssertEqual(system.enableCount, 0)
        XCTAssertTrue(system.submittedRequests.isEmpty)
    }

    func testStartFullFlowInstallsThenEnables() async throws {
        let (controller, system, _, _, _) = makeController()
        try await controller.start()
        XCTAssertEqual(system.submittedRequests, [.activate])
        XCTAssertEqual(system.installCount, 1)
        XCTAssertEqual(system.enableCount, 1)
        XCTAssertEqual(controller.snapshot.state, .running)
    }

    func testStopDisablesFilterAndStops() async throws {
        let (controller, system, _, _, _) = makeController()
        try await controller.stop()
        XCTAssertEqual(system.disableCount, 1)
        XCTAssertEqual(controller.snapshot.state, .stopped)
    }

    func testStartFailureWhenEnableFails() async throws {
        let (controller, system, _, _, _) = makeController()
        system.enableError = NSError(domain: "NE", code: 7, userInfo: [NSLocalizedDescriptionKey: "启用失败"])
        try await controller.start()
        guard case .failed = controller.snapshot.state else {
            return XCTFail("期望 failed 状态")
        }
    }

    func testInstallFilterWhenAlreadyEnabledPreservesLegacyFilterNotInstalled() async throws {
        let (controller, system, _, _, _) = makeController()
        system.filterEnabled = true
        try await controller.installFilter()
        XCTAssertEqual(controller.snapshot.state, .filterNotInstalled)
        XCTAssertEqual(system.installCount, 0)
    }

    func testRefreshSubmitsPropertiesAndLoadsFilter() async {
        let (controller, system, _, _, _) = makeController()
        system.filterEnabled = true
        await controller.refresh()
        XCTAssertEqual(system.submittedRequests, [.properties])
        XCTAssertEqual(controller.snapshot.state, .running)
    }

    func testFilterObserverUpdateDrivesState() async throws {
        let (controller, system, _, _, _) = makeController()
        controller.startObserving()
        system.observerHandler?(false)
        XCTAssertEqual(controller.snapshot.state, .stopped)
        system.observerHandler?(true)
        XCTAssertEqual(controller.snapshot.state, .running)
    }

    // MARK: - 观察流

    func testObserveYieldsCurrentAndUpdates() async {
        let (controller, _, _, _, _) = makeController()
        let task = Task {
            var received: [FirewallState] = []
            for await snapshot in controller.observe() {
                received.append(snapshot.state)
                if received.count == 2 { return received }
            }
            return received
        }
        try? await Task.sleep(for: .milliseconds(50))
        controller.systemExtensionNeedsUserApproval()
        let states = await task.value
        XCTAssertEqual(states.count, 2)
        XCTAssertEqual(states.first, .unknown)   // 订阅即当前快照
        XCTAssertEqual(states.last, .systemExtensionApprovalNeeded)
    }

    // MARK: - 决策路径（IPC promptUser）

    func testPromptAllowCreatesAllowedEventAndRespondsTrue() async throws {
        let (controller, _, _, settings, events) = makeController()
        settings.allowRules["com.app"] = true
        var decision: Bool?
        controller.handlePrompt(
            id: "com.app",
            hostname: "example.com",
            port: "443",
            direction: .outbound,
            responseHandler: { decision = $0 }
        )
        XCTAssertEqual(decision, true)
        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(events.created.count, 1)
        XCTAssertEqual(events.created.first?.status, .allowed)
        XCTAssertEqual(events.created.first?.direction, .outbound)
        XCTAssertEqual(events.created.first?.appId, "com.app")
    }

    func testPromptDenyCreatesRejectedEventAndRespondsFalse() async throws {
        let (controller, _, _, settings, events) = makeController()
        settings.allowRules["com.blocked"] = false
        var decision: Bool?
        controller.handlePrompt(
            id: "com.blocked",
            hostname: "evil.example",
            port: "80",
            direction: .inbound,
            responseHandler: { decision = $0 }
        )
        XCTAssertEqual(decision, false)
        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(events.created.count, 1)
        XCTAssertEqual(events.created.first?.status, .rejected)
        XCTAssertEqual(events.created.first?.direction, .inbound)
    }

    func testPromptBridgeForwardsToController() async throws {
        let (controller, _, _, settings, events) = makeController()
        let bridge = PromptUserBridge(controller: controller)
        settings.allowRules["com.bridge"] = true

        // @Sendable 回调经流收集，避免跨隔离捕获可变变量。
        let (stream, continuation) = AsyncStream<Bool>.makeStream()
        bridge.promptUser(
            id: "com.bridge",
            hostname: "h",
            port: "1",
            direction: .outbound,
            responseHandler: { continuation.yield($0) }
        )
        var decision: Bool?
        for await value in stream {
            decision = value
            break
        }
        continuation.finish()
        XCTAssertEqual(decision, true)
        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(events.created.count, 1)
    }

    // MARK: - 插件生命周期

    func testPluginLifecycleRegistersObservesAndShutsDown() async throws {
        let system = MockSystemAdapter()
        let ipc = MockIPCAdapter()
        let plugin = PluginFirewall(system: system, ipc: ipc)

        // Mock 插件目录：persistence(appsettings/eventstore 的依赖占位)、
        // appsettings、eventstore —— 与生产插件 id 一致，验证依赖排序。
        let kernel = KernelCoreContainer()
        try await kernel.startAsync(plugins: [
            MockProviderPlugin(id: "persistence", order: 1, dependencies: []),
            MockProviderPlugin(
                id: "appsettings", order: 10, dependencies: ["persistence"],
                settings: MockSettings()
            ),
            MockProviderPlugin(
                id: "eventstore", order: 10, dependencies: ["persistence"],
                events: MockEvents()
            ),
            plugin,
        ])

        // onBoot：FirewallProviding 已注册。
        let firewall = kernel.resolveProvider(FirewallProviding.self)
        XCTAssertNotNil(firewall)
        // onReady：观察者已注册、IPC 已关联、状态已刷新（默认 stopped）。
        XCTAssertNotNil(system.observerHandler)
        XCTAssertTrue(system.workspaceRegistered)
        XCTAssertEqual(ipc.registerCount, 1)
        XCTAssertEqual(firewall?.snapshot.state, .stopped)

        try await kernel.stopAsync()

        // onShutdown：观察者移除、工作区注销、IPC 断开、Provider 撤回。
        XCTAssertNil(system.observerHandler)
        XCTAssertTrue(system.workspaceUnregistered)
        XCTAssertEqual(ipc.unregisterCount, 1)
        XCTAssertNil(kernel.resolveProvider(FirewallProviding.self))
    }

    func testPluginFailsWithoutEventStoreDependency() {
        let kernel = KernelCoreContainer()
        let plugin = PluginFirewall(system: MockSystemAdapter(), ipc: MockIPCAdapter())
        XCTAssertThrowsError(try kernel.start(plugins: [plugin])) { error in
            XCTAssertNotNil(error)
        }
        XCTAssertEqual(kernel.lifecycleState, .stopped)
    }
}

// MARK: - Mock 插件（仅测试目录用，id 与生产插件一致）

/// 注册 Mock Provider 的最小插件。
@MainActor
private final class MockProviderPlugin: SuperPlugin {
    let id: String
    var order: Int
    var dependencies: [String]
    let metadata = PluginMetadata(name: "Mock", version: "1.0", policy: .enabledByDefault)
    private let settings: MockSettings?
    private let events: MockEvents?

    init(id: String, order: Int, dependencies: [String], settings: MockSettings? = nil, events: MockEvents? = nil) {
        self.id = id
        self.order = order
        self.dependencies = dependencies
        self.settings = settings
        self.events = events
    }

    func onBoot(kernel: KernelCoreContainer) throws {
        if let settings {
            try kernel.registerProvider(settings, for: AppSettingsProviding.self, owner: id)
        }
        if let events {
            try kernel.registerProvider(events, for: FirewallEventsProviding.self, owner: id)
        }
    }
}
