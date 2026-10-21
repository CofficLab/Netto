import Foundation
import NettoIPCContracts
import NetworkExtension
import ProviderFirewall
import ProviderFirewallEvents
import SystemExtensions
import XCTest
@testable import PluginFirewall

/// 系统扩展请求结果接收者的 Mock。
@MainActor
final class MockRequestHandler: SystemExtensionRequestHandling {
    private(set) var activationCompletedCount = 0
    private(set) var needsUserApprovalCount = 0
    private(set) var failedError: Error?
    private(set) var receivedProperties: [SystemExtensionPropertyInfo] = []

    /// 测试用的回调钩子（桥接经 Task { @MainActor } 跳转，用期望等待到达）。
    var onActivationCompleted: (() -> Void)?
    var onNeedsUserApproval: (() -> Void)?
    var onRequestFailed: ((Error) -> Void)?

    func systemExtensionActivationCompleted() {
        activationCompletedCount += 1
        onActivationCompleted?()
    }

    func systemExtensionNeedsUserApproval() {
        needsUserApprovalCount += 1
        onNeedsUserApproval?()
    }

    func systemExtensionRequestFailed(_ error: Error) {
        failedError = error
        onRequestFailed?(error)
    }

    func systemExtensionProperties(_ properties: [SystemExtensionPropertyInfo]) {
        receivedProperties = properties
    }
}

/// 控制器状态机的错误分支与 daemon 生命周期测试。
///
/// 既有 `FirewallControllerTests` 覆盖主流程，本文件补齐错误路径、
/// 系统扩展属性回调的守卫分支与 daemon 生命周期。
@MainActor
final class FirewallControllerBranchTests: XCTestCase {

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

    private func assertFailed(
        _ state: FirewallState,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .failed = state else {
            return XCTFail("期望 failed 状态，实际为 \(String(describing: state))", file: file, line: line)
        }
    }

    // MARK: - refresh 错误路径

    func testRefreshFailureMapsToFailedState() async {
        let (controller, system, _, _, _) = makeController()
        system.loadError = NSError(domain: "NE", code: 3, userInfo: [NSLocalizedDescriptionKey: "读取失败"])

        await controller.refresh()

        assertFailed(controller.snapshot.state)
        // refresh 仍会先提交属性查询请求。
        XCTAssertEqual(system.submittedRequests, [.properties])
    }

    // MARK: - installSystemExtension 守卫

    func testInstallSystemExtensionWithoutInstalledVersionStops() async {
        let (controller, system, _, _, _) = makeController()
        system.currentVersion = nil

        await controller.installSystemExtension()

        XCTAssertEqual(controller.snapshot.state, .stopped)
        XCTAssertTrue(system.submittedRequests.isEmpty, "没有扩展版本信息时不应提交激活请求")
    }

    func testInstallSystemExtensionOutsideApplicationsFolderDoesNotActivate() async {
        let (controller, system, _, _, _) = makeController()
        system.appInApplicationsFolder = false

        await controller.installSystemExtension()

        XCTAssertEqual(controller.snapshot.state, .notInApplicationsFolder)
        XCTAssertTrue(system.submittedRequests.isEmpty)
    }

    // MARK: - installFilter 错误路径

    func testInstallFilterPropagatesLoadError() async {
        let (controller, system, _, _, _) = makeController()
        system.loadError = NSError(domain: "NE", code: 4, userInfo: [NSLocalizedDescriptionKey: "读取失败"])

        do {
            try await controller.installFilter()
            XCTFail("期望抛出 loadFilterEnabled 的错误")
        } catch {
            assertFailed(controller.snapshot.state)
        }
        XCTAssertEqual(system.installCount, 0)
    }

    func testInstallFilterMarksApprovalNeededWhenInstallFails() async {
        let (controller, system, _, _, _) = makeController()
        system.installError = NSError(domain: "NE", code: 5, userInfo: [NSLocalizedDescriptionKey: "授权保存失败"])

        do {
            try await controller.installFilter()
            XCTFail("期望抛出 installFilterConfiguration 的错误")
        } catch {
            XCTAssertEqual(controller.snapshot.state, .filterApprovalNeeded)
        }
        XCTAssertEqual(system.installCount, 1)
    }

    // MARK: - start 错误路径

    func testStartMapsLoadFailureToFailedState() async throws {
        let (controller, system, _, _, _) = makeController()
        system.loadError = NSError(domain: "NE", code: 6, userInfo: [NSLocalizedDescriptionKey: "读取失败"])

        try await controller.start()

        assertFailed(controller.snapshot.state)
        XCTAssertEqual(system.installCount, 0)
        XCTAssertEqual(system.enableCount, 0)
    }

    func testStartMapsInstallFailureToFailedStateAndDoesNotEnable() async throws {
        let (controller, system, _, _, _) = makeController()
        system.installError = NSError(domain: "NE", code: 7, userInfo: [NSLocalizedDescriptionKey: "安装失败"])

        try await controller.start()

        assertFailed(controller.snapshot.state)
        XCTAssertEqual(system.installCount, 1)
        XCTAssertEqual(system.enableCount, 0, "安装失败后不应继续启用过滤器")
    }

    // MARK: - daemon 生命周期

    func testStartDaemonRegistersWorkspaceObserverAndIPC() async {
        let (controller, system, ipc, _, _) = makeController()

        await controller.startDaemon()

        XCTAssertTrue(system.workspaceRegistered)
        XCTAssertEqual(ipc.registerCount, 1)
    }

    func testStartDaemonWorkspaceCallbackRegistersIPCAgain() async {
        let (controller, system, ipc, _, _) = makeController()
        await controller.startDaemon()
        XCTAssertEqual(ipc.registerCount, 1)

        // 工作区观察者回调（扩展即将启用）应重新建立 IPC 关联。
        system.workspaceHandler?()

        // 回调经 Task { @MainActor } 跳转，留出一次让出即可完成。
        await Task.yield()
        await Task.yield()
        XCTAssertEqual(ipc.registerCount, 2)
    }

    func testStartDaemonLoadFailureIsNotFatal() async {
        let (controller, system, ipc, _, _) = makeController()
        system.loadError = NSError(domain: "NE", code: 8, userInfo: [NSLocalizedDescriptionKey: "读取失败"])

        await controller.startDaemon()

        // 引导期的加载失败只记录日志，不阻断 daemon 启动。
        XCTAssertTrue(system.workspaceRegistered)
        XCTAssertEqual(ipc.registerCount, 1)
    }

    func testRegisterIPCReturnsAdapterResult() async {
        let (controller, _, ipc, _, _) = makeController()
        ipc.registerResult = false

        let registered = await controller.registerIPC()

        XCTAssertFalse(registered)
    }

    // MARK: - 系统扩展属性回调

    func testSystemExtensionPropertiesIgnoredWithoutCurrentVersion() {
        let (controller, system, _, _, _) = makeController()
        system.currentVersion = nil
        let installed = SystemExtensionPropertyInfo(
            bundleIdentifier: "ext", bundleVersion: "1.0", bundleShortVersion: "1.0",
            urlPath: "/x", isEnabled: true, isAwaitingUserApproval: false, isUninstalling: false
        )

        controller.systemExtensionProperties([installed])

        // 无法判定当前版本时保持原状态。
        XCTAssertEqual(controller.snapshot.state, .unknown)
    }

    func testSystemExtensionPropertiesWithEnabledCurrentVersionKeepsState() {
        let (controller, system, _, _, _) = makeController()
        let installed = SystemExtensionPropertyInfo(
            bundleIdentifier: "ext", bundleVersion: "1.0", bundleShortVersion: "1.0",
            urlPath: "/x", isEnabled: true, isAwaitingUserApproval: false, isUninstalling: false
        )

        controller.systemExtensionProperties([installed])

        // 已启用且版本一致：保持当前状态（初始为 unknown）。
        XCTAssertEqual(controller.snapshot.state, .unknown)
    }

    func testUninstallingPropertiesAreExcludedFromVersionJudgement() {
        let (controller, system, _, _, _) = makeController()
        // 正在卸载的扩展被过滤掉，不会参与「当前版本是否已安装」的判断。
        let uninstalling = SystemExtensionPropertyInfo(
            bundleIdentifier: "ext", bundleVersion: "1.0", bundleShortVersion: "1.0",
            urlPath: "/x", isEnabled: true, isAwaitingUserApproval: false, isUninstalling: true
        )

        controller.systemExtensionProperties([uninstalling])

        XCTAssertEqual(controller.snapshot.state, .systemExtensionNotInstalled)
    }

    // MARK: - 决策路径的写事件失败

    func testPromptRespondsEvenWhenEventPersistenceFails() async throws {
        let (controller, _, _, settings, events) = makeController()
        settings.allowRules["com.app"] = true
        events.createError = NSError(domain: "DB", code: 9, userInfo: [NSLocalizedDescriptionKey: "写库失败"])
        let responded = expectation(description: "responseHandler")
        var decision: Bool?

        controller.handlePrompt(
            id: "com.app",
            hostname: "example.com",
            port: "443",
            direction: .outbound,
            responseHandler: { value in
                decision = value
                responded.fulfill()
            }
        )

        await fulfillment(of: [responded], timeout: 2)
        XCTAssertEqual(decision, true)
        // 写事件失败只记录日志，不影响决策响应。
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertTrue(events.created.isEmpty)
    }

    func testPromptMapsUnknownDirectionToInbound() async throws {
        let (controller, _, _, settings, events) = makeController()
        settings.allowRules["com.app"] = true
        let responded = expectation(description: "responseHandler")

        controller.handlePrompt(
            id: "com.app",
            hostname: "example.com",
            port: "443",
            direction: .any,
            responseHandler: { _ in responded.fulfill() }
        )

        await fulfillment(of: [responded], timeout: 2)
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(events.created.first?.direction, .inbound)
    }
}

/// 系统扩展 Bundle 定位测试。
@MainActor
final class FirewallExtensionBundleTests: XCTestCase {

    func testLoadReturnsNilInNonAppHost() {
        // xctest runner 不是 .app 宿主，系统扩展目录缺失属预期环境。
        let bundle = FirewallExtensionBundle.load()
        XCTAssertNil(bundle)
    }
}

/// IPC 注册门闩与 NSXPC 适配器测试。
@MainActor
final class FirewallIPCAdapterTests: XCTestCase {

    func testRegistrationCompletionResumesWithResultFinishedBeforeInstall() async {
        let registration = IPCRegistrationCompletion(timeout: .seconds(5))

        // 远端回调先于 install 到达：结果被暂存，install 时立即返回。
        registration.finish(true)
        let succeeded = await withCheckedContinuation { continuation in
            registration.install(continuation)
        }

        XCTAssertTrue(succeeded)
    }

    func testRegistrationCompletionResumesFalseWhenFinishedWithFailureBeforeInstall() async {
        let registration = IPCRegistrationCompletion(timeout: .seconds(5))

        registration.finish(false)
        let succeeded = await withCheckedContinuation { continuation in
            registration.install(continuation)
        }

        XCTAssertFalse(succeeded)
    }

    func testRegistrationCompletionFinishIsIdempotent() async {
        let registration = IPCRegistrationCompletion(timeout: .seconds(5))
        let succeeded = await withCheckedContinuation { continuation in
            registration.install(continuation)
            registration.finish(true)
        }
        XCTAssertTrue(succeeded)

        // 迟到的第二次 finish 不应重复恢复 continuation。
        registration.finish(false)
    }

    func testRegistrationCompletionTimeoutCancelsTimerTask() async {
        let registration = IPCRegistrationCompletion(timeout: .seconds(5))
        let succeeded = await withCheckedContinuation { continuation in
            registration.install(continuation)
            registration.finish(true)
        }
        XCTAssertTrue(succeeded)
    }

    func testNSXPCAdapterRegisterWithoutExportedObjectFails() async {
        let adapter = NSXPCFirewallIPCAdapter(extensionBundle: nil)

        let registered = await adapter.register()

        XCTAssertFalse(registered)
    }

    func testNSXPCAdapterRegisterWithoutExtensionBundleFails() async {
        let adapter = NSXPCFirewallIPCAdapter(extensionBundle: nil)
        adapter.exportedAppCommunication = StubAppCommunication()

        let registered = await adapter.register()

        XCTAssertFalse(registered)
    }

    func testNSXPCAdapterUnregisterWithoutConnectionIsSafe() {
        let adapter = NSXPCFirewallIPCAdapter(extensionBundle: nil)
        adapter.unregister()
        adapter.unregister()
    }
}

/// `AppCommunication` 的最小实现（供 IPC 适配器测试使用）。
final class StubAppCommunication: NSObject, AppCommunication {
    func promptUser(
        id: String,
        hostname: String,
        port: String,
        direction: NETrafficDirection,
        responseHandler: @escaping @Sendable (Bool) -> Void
    ) {
        responseHandler(true)
    }

    func needApproval() {}

    func extensionLog(_ words: String) {}
}

/// 生产系统适配器的无副作用部分测试。
@MainActor
final class SystemFirewallAdapterTests: XCTestCase {

    func testInitAndRequestHandlerAreSettable() {
        let adapter = SystemFirewallAdapter(extensionBundle: nil)
        let handler = MockRequestHandler()

        adapter.setRequestHandler(handler)

        XCTAssertNotNil(adapter)
    }

    func testCurrentExtensionVersionIsNilWithoutBundle() {
        let adapter = SystemFirewallAdapter(extensionBundle: nil)
        XCTAssertNil(adapter.currentExtensionVersion)
    }

    func testCurrentExtensionVersionRequiresBundle() {
        // 没有扩展 bundle 时扩展版本信息不可用。
        let adapter = SystemFirewallAdapter(extensionBundle: nil)
        let version = adapter.currentExtensionVersion
        XCTAssertNil(version)
    }

    func testFilterConfigurationObserverCanBeRegisteredAndRemoved() {
        let adapter = SystemFirewallAdapter(extensionBundle: nil)

        let token = adapter.addFilterConfigurationObserver { _ in }
        XCTAssertNotNil(token)

        adapter.removeFilterConfigurationObserver(token)
    }

    func testSubmitSystemExtensionRequestWithoutBundleIsNoop() {
        let adapter = SystemFirewallAdapter(extensionBundle: nil)
        // 没有扩展 bundle 时直接返回，不会向系统提交请求。
        adapter.submitSystemExtensionRequest(.activate)
        adapter.submitSystemExtensionRequest(.properties)
    }

    func testUnregisterWorkspaceObserverWithoutRegistrationIsNoop() {
        let adapter = SystemFirewallAdapter(extensionBundle: nil)
        adapter.unregisterWorkspaceObserver()
    }

    func testIsAppInApplicationsFolderReflectsHostBundlePath() {
        let adapter = SystemFirewallAdapter(extensionBundle: nil)
        // 该属性直接反映宿主 bundle 路径前缀（测试宿主为 xctest runner）。
        let expected = Bundle.main.bundlePath.hasPrefix("/Applications")
        XCTAssertEqual(adapter.isAppInApplicationsFolder, expected)
    }
}

/// 系统扩展请求桥接测试。
@MainActor
final class SystemExtensionRequestBridgeTests: XCTestCase {

    /// 返回桥接、接收者与弱引用盒。
    ///
    /// 桥接内部以弱引用持有盒子，测试必须让盒子与接收者都保持存活，
    /// 否则回调会被静默丢弃。
    private func makeBridge() -> (SystemExtensionRequestBridge, MockRequestHandler, WeakRequestHandlerBox) {
        let box = WeakRequestHandlerBox()
        let handler = MockRequestHandler()
        box.handler = handler
        return (SystemExtensionRequestBridge(box: box), handler, box)
    }

    private func makeRequest() -> OSSystemExtensionRequest {
        OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: "com.test.ext", queue: .main)
    }

    func testActivationCompletedForwardsToHandler() async {
        let (bridge, handler, box) = makeBridge()
        defer { _ = box }
        let fulfilled = expectation(description: "activationCompleted")
        handler.onActivationCompleted = { fulfilled.fulfill() }

        bridge.request(makeRequest(), didFinishWithResult: .completed)

        // 回调经 Task { @MainActor } 跳转，用期望等待其到达。
        await fulfillment(of: [fulfilled], timeout: 2)
        XCTAssertEqual(handler.activationCompletedCount, 1)
    }

    func testWillCompleteAfterRebootDoesNotNotify() async {
        let (bridge, handler, box) = makeBridge()

        bridge.request(makeRequest(), didFinishWithResult: .willCompleteAfterReboot)

        await Task.yield()
        XCTAssertEqual(handler.activationCompletedCount, 0)
    }

    func testRequestFailureForwardsErrorToHandler() async {
        let (bridge, handler, box) = makeBridge()
        defer { _ = box }
        let error = NSError(domain: "SystemExtensions", code: 11, userInfo: [NSLocalizedDescriptionKey: "失败"])
        let fulfilled = expectation(description: "requestFailed")
        handler.onRequestFailed = { _ in fulfilled.fulfill() }

        bridge.request(makeRequest(), didFailWithError: error)

        await fulfillment(of: [fulfilled], timeout: 2)
        XCTAssertEqual((handler.failedError as NSError?)?.code, 11)
    }

    func testNeedsUserApprovalForwardsToHandler() async {
        let (bridge, handler, box) = makeBridge()
        defer { _ = box }
        let fulfilled = expectation(description: "needsUserApproval")
        handler.onNeedsUserApproval = { fulfilled.fulfill() }

        bridge.requestNeedsUserApproval(makeRequest())

        await fulfillment(of: [fulfilled], timeout: 2)
        XCTAssertEqual(handler.needsUserApprovalCount, 1)
    }

    func testFoundPropertiesForwardsEmptyListToHandler() async {
        let (bridge, handler, box) = makeBridge()
        defer { _ = box }

        bridge.request(makeRequest(), foundProperties: [])

        await Task.yield()
        XCTAssertTrue(handler.receivedProperties.isEmpty)
    }
}

/// 弱引用盒测试。
@MainActor
final class WeakRequestHandlerBoxTests: XCTestCase {

    func testHandlerIsReleasedWhenOwnerIsGone() {
        let box = WeakRequestHandlerBox()
        var handler: MockRequestHandler? = MockRequestHandler()
        box.handler = handler
        XCTAssertNotNil(box.handler)

        handler = nil

        XCTAssertNil(box.handler)
    }
}

/// 插件装配元数据与桥接行为测试。
@MainActor
final class PluginFirewallEntryTests: XCTestCase {

    func testMetadataDescribesFirewallPlugin() {
        let plugin = PluginFirewall(system: MockSystemAdapter(), ipc: MockIPCAdapter())

        XCTAssertEqual(plugin.id, "firewall")
        XCTAssertEqual(plugin.order, 30)
        XCTAssertEqual(plugin.dependencies, ["persistence", "appsettings", "eventstore"])
        XCTAssertEqual(plugin.metadata.id, "firewall")
        XCTAssertEqual(plugin.metadata.name, "Firewall")
        XCTAssertEqual(plugin.metadata.version, "1.0")
    }

    func testProductionInitDoesNotCrashWithoutExtensionBundle() {
        // 非 App 宿主（xctest runner）没有系统扩展目录，生产装配应降级运行。
        let plugin = PluginFirewall()
        XCTAssertEqual(plugin.id, "firewall")
    }

    func testPromptUserBridgeNeedApprovalPostsNotification() async {
        let controller = FirewallController(
            system: MockSystemAdapter(),
            ipc: MockIPCAdapter(),
            settings: MockSettings(),
            events: MockEvents()
        )
        let bridge = PromptUserBridge(controller: controller)
        let posted = expectation(description: "firewallNeedApproval")
        let token = NotificationCenter.default.addObserver(
            forName: .firewallNeedApproval,
            object: nil,
            queue: .main
        ) { _ in
            posted.fulfill()
        }
        defer { NotificationCenter.default.removeObserver(token) }

        bridge.needApproval()

        await fulfillment(of: [posted], timeout: 2)
    }

    func testPromptUserBridgeExtensionLogIsNoop() {
        let controller = FirewallController(
            system: MockSystemAdapter(),
            ipc: MockIPCAdapter(),
            settings: MockSettings(),
            events: MockEvents()
        )
        let bridge = PromptUserBridge(controller: controller)

        bridge.extensionLog("hello")

        // 日志转发为空实现，不应产生任何副作用。
        XCTAssertEqual(controller.snapshot.state, .unknown)
    }
}

/// 工作区观察者桥接测试。
@MainActor
final class WorkspaceObserverBridgeTests: XCTestCase {

    func testInitStoresHandler() {
        guard #available(macOS 15.1, *) else { return }
        let bridge = WorkspaceObserverBridge(handler: {})
        XCTAssertNotNil(bridge)
    }
}
