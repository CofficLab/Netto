import AppKit
import Foundation
import NetworkExtension
import OSLog
import ProviderAppSettings
import ProviderFirewall
import ProviderFirewallEvents

/// 防火墙控制器 —— `FirewallProviding` 实现与系统扩展请求接收者。
///
/// 逐项保留旧 `FirewallService` 行为与状态语义：
/// - 状态机覆盖旧 `FilterStatus` 全量状态（未安装/未激活/审批/Applications/
///   过滤器未安装/错误等），不合并为 stopped。
/// - `refresh()` 先请求系统扩展属性、再读取过滤器启用状态（旧 refreshStatus）。
/// - 系统扩展属性回调按旧逻辑覆盖状态（extensionNotActivated 等），
///   激活完成时若处于未就绪态则回落到 stopped。
/// - `promptUser` 决策路径：AppSettings 同步决策 + FirewallEvents 异步写事件。
///
/// 线程/actor：`@MainActor`；系统回调经适配器桥接后在此处理；
/// 不持有任何 shared singleton，系统/IPC 均经注入的适配器访问。
@MainActor
final class FirewallController: FirewallProviding, SystemExtensionRequestHandling {
    private let system: any FirewallSystemAdapting
    private let ipc: any FirewallIPCServing
    private let settings: any AppSettingsProviding
    private let events: any FirewallEventsProviding
    private let logger = Logger(subsystem: "com.yueyi.TravelMode.PluginFirewall", category: "firewall")

    private var filterObserverToken: Any?
    private var appActivationObserverToken: Any?
    private var snapshotContinuations: [UUID: AsyncStream<FirewallSnapshot>.Continuation] = [:]
    private var awaitingApproval = false
    private var ipcRecoveryTask: Task<Void, Never>?

    private(set) var snapshot: FirewallSnapshot
    private var state: FirewallState

    init(
        system: any FirewallSystemAdapting,
        ipc: any FirewallIPCServing,
        settings: any AppSettingsProviding,
        events: any FirewallEventsProviding,
        initialState: FirewallState = .unknown
    ) {
        self.system = system
        self.ipc = ipc
        self.settings = settings
        self.events = events
        self.state = initialState
        self.snapshot = FirewallSnapshot(state: initialState)

        // 注册成功后的 IPC 意外断开：必须重连，否则扩展侧放行一切流量。
        ipc.connectionLossHandler = { [weak self] in
            self?.recoverIPCConnection()
        }
    }

    // MARK: - 状态更新

    private func updateState(_ newState: FirewallState) {
        guard newState != state else { return }
        let oldValue = state
        state = newState
        snapshot = FirewallSnapshot(state: state, lastUpdated: Date())
        logger.info("状态 \(String(describing: oldValue)) -> \(String(describing: newState))")
        snapshotContinuations.values.forEach { $0.yield(snapshot) }
    }

    private func failure(_ error: Error) -> FirewallState {
        let nsError = error as NSError
        return .failed(FirewallFailure(domain: nsError.domain, code: nsError.code, message: error.localizedDescription))
    }

    // MARK: - FirewallProviding

    func refresh() async {
        // 先请求系统扩展属性（异步回调可能覆盖下面的运行/停止状态）。
        system.submitSystemExtensionRequest(.properties)

        do {
            let enabled = try await system.loadFilterEnabled()
            // 扩展未就绪时保留引导状态，避免与异步属性回调竞争后被过滤器结果覆盖。
            guard !Self.isExtensionGateState(state) else { return }
            updateState(enabled ? .running : .stopped)
        } catch {
            updateState(failure(error))
        }
    }

    func installSystemExtension() async {
        // 旧 activateSystemExtension 的守卫路径。
        guard system.isAppInApplicationsFolder else {
            updateState(.notInApplicationsFolder)
            return
        }
        guard system.currentExtensionVersion != nil else {
            updateState(.stopped)
            return
        }
        system.submitSystemExtensionRequest(.activate)
    }

    func installFilter() async throws {
        let enabled: Bool
        do {
            enabled = try await system.loadFilterEnabled()
        } catch {
            updateState(failure(error))
            throw error
        }

        guard !enabled else {
            // 旧行为保留：过滤器已启用时不再重复安装。
            updateState(.filterNotInstalled)
            return
        }

        do {
            try await system.installFilterConfiguration()
        } catch {
            // 旧 installFilter：授权保存失败 → filterNeedApproval 并抛出。
            updateState(.filterApprovalNeeded)
            throw error
        }
    }

    func start() async throws {
        var enabled = false
        do {
            enabled = try await system.loadFilterEnabled()
        } catch {
            updateState(failure(error))
        }

        if enabled {
            updateState(.running)
            return
        }

        await installSystemExtension()

        do {
            try await installFilter()
        } catch {
            updateState(failure(error))
            return
        }

        do {
            try await system.enableFilter()
            updateState(.running)
        } catch {
            updateState(failure(error))
        }
    }

    func stop() async throws {
        try await system.disableFilter()
        updateState(.stopped)
    }

    func observe() -> AsyncStream<FirewallSnapshot> {
        let observerID = UUID()
        return AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }
            snapshotContinuations[observerID] = continuation
            continuation.yield(snapshot)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.snapshotContinuations.removeValue(forKey: observerID)
                }
            }
        }
    }

    // MARK: - 观察者与 daemon（onReady/onShutdown 生命周期）

    /// 注册过滤器配置变更观察者（旧 setObserver）与应用激活观察者。
    ///
    /// 应用激活时必须重算状态：用户可能刚从系统设置里启用/禁用了扩展，
    /// 仅靠系统扩展事件会在启用完成前触发查询而读到旧值。
    func startObserving() {
        guard filterObserverToken == nil else { return }
        filterObserverToken = system.addFilterConfigurationObserver { [weak self] in
            // 配置变了必须重新加载偏好再判断：`NEFilterManager` 的属性是
            // 进程内副本，直接读会拿到上一次的旧值。
            Task { @MainActor in
                await self?.refresh()
            }
        }
        appActivationObserverToken = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }

    /// daemon 启动（迁移自旧 runDaemon）：
    /// 1. 注册系统扩展工作区观察者（macOS 15.1+）。
    /// 2. 加载过滤器配置（失败仅记录，不阻断）。
    /// 3. 与 Extension 建立 IPC 关联。
    func startDaemon() async {
        system.registerWorkspaceObserver { [weak self] isBecomingEnabled in
            guard let self else { return }
            Task { @MainActor in
                if isBecomingEnabled {
                    _ = await self.registerIPC()
                }
                // 启用/禁用/删除都必须重算状态，否则引导会停留在过期状态。
                await self.refresh()
            }
        }

        do {
            _ = try await system.loadFilterEnabled()
        } catch {
            logger.error("Boot 加载过滤器配置失败: \(error.localizedDescription)")
        }

        if await registerIPC() == false {
            logger.error("与系统扩展建立 IPC 关联失败")
        }
    }

    /// 与 Extension 建立 IPC 关联（旧 registerWithProvider）。
    func registerIPC() async -> Bool {
        await ipc.register()
    }

    /// IPC 注册成功后的意外断开（扩展进程退出/连接失效）后的恢复流程。
    ///
    /// 扩展侧在无 App 连接时会放行一切流量，因此必须重连；重连失败时把
    /// 状态切到 failed，避免界面继续显示「运行中」而实际已失效。
    private func recoverIPCConnection() {
        guard ipcRecoveryTask == nil else { return }
        ipcRecoveryTask = Task { [weak self] in
            guard let self else { return }
            for attempt in 1...Self.ipcRecoveryAttempts {
                if attempt > 1 {
                    try? await Task.sleep(for: .milliseconds(300 * attempt))
                }
                if await self.registerIPC() {
                    await self.refresh()
                    self.ipcRecoveryTask = nil
                    return
                }
            }
            self.updateState(.failed(FirewallFailure(
                domain: "com.yueyi.TravelMode.ipc",
                code: -1,
                message: "与系统扩展的连接已断开且重连失败，防火墙规则可能未生效"
            )))
            self.ipcRecoveryTask = nil
        }
    }

    /// IPC 重连尝试次数。
    private static let ipcRecoveryAttempts = 3

    /// 停止全部外部资源（onShutdown 调用）。
    func shutdown() {
        ipcRecoveryTask?.cancel()
        ipcRecoveryTask = nil
        ipc.connectionLossHandler = nil
        if let token = filterObserverToken {
            system.removeFilterConfigurationObserver(token)
            filterObserverToken = nil
        }
        if let token = appActivationObserverToken {
            NotificationCenter.default.removeObserver(token)
            appActivationObserverToken = nil
        }
        system.unregisterWorkspaceObserver()
        ipc.unregister()
        snapshotContinuations.values.forEach { $0.finish() }
        snapshotContinuations.removeAll()
    }

    // MARK: - SystemExtensionRequestHandling

    func systemExtensionActivationCompleted() {
        awaitingApproval = false
        // 旧行为：未就绪态（未安装/需更新/待审批/未激活）回落 stopped。
        if Self.isExtensionGateState(state) {
            updateState(.stopped)
        }
    }

    /// 仅由「系统扩展未就绪」推导出的状态；扩展确认已启用后必须清除。
    private static func isExtensionGateState(_ state: FirewallState) -> Bool {
        switch state {
        case .extensionNotActivated,
             .systemExtensionNotInstalled,
             .systemExtensionNeedsUpdate,
             .systemExtensionApprovalNeeded:
            return true
        default:
            return false
        }
    }

    func systemExtensionNeedsUserApproval() {
        awaitingApproval = true
        updateState(.systemExtensionApprovalNeeded)
    }

    func systemExtensionRequestFailed(_ error: Error) {
        updateState(failure(error))
    }

    func systemExtensionProperties(_ properties: [SystemExtensionPropertyInfo]) {
        guard let currentVersion = system.currentExtensionVersion else {
            logger.error("无法获取当前 app 的系统扩展版本信息")
            return
        }

        // 旧行为：跳过正在卸载的扩展参与当前/最新版本判断。
        let active = properties.filter { !$0.isUninstalling }

        // 同一版本可能残留多份拷贝（替换 App 后待重启清理），优先采用已启用的一份；
        // 否则会把「已激活」误判为「未激活」。
        let matching = active.filter { $0.bundleVersion == currentVersion.version }
        let currentVersionInstalled = matching.first(where: { $0.isEnabled }) ?? matching.first

        var latestVersion: String = ""
        var latestProperty: SystemExtensionPropertyInfo?

        for property in active where property.bundleVersion > latestVersion {
            latestVersion = property.bundleVersion
            latestProperty = property
        }

        if let currentInstalled = currentVersionInstalled {
            var nextState = state
            if currentInstalled.isEnabled == false {
                nextState = .extensionNotActivated
            } else if Self.isExtensionGateState(state) {
                // 扩展确认已启用：清除仅由「扩展未就绪」推导出的状态，
                // 运行/停止交由 refresh 的过滤器读取决定。
                nextState = .stopped
            }
            updateState(nextState)
        } else {
            if latestProperty != nil {
                // 当前版本未安装但有其他版本：需更新，并静默升级（激活请求）。
                updateState(.systemExtensionNeedsUpdate)
                system.submitSystemExtensionRequest(.activate)
            } else {
                updateState(.systemExtensionNotInstalled)
            }
        }
    }

    // MARK: - 决策（AppCommunication 回调入口）

    /// 处理 Extension 的决策请求：同步决策 + 写事件（迁移自旧 promptUser）。
    func handlePrompt(
        id: String,
        hostname: String,
        port: String,
        direction: NETrafficDirection,
        responseHandler: @escaping (Bool) -> Void
    ) {
        let shouldAllow = settings.shouldAllowSync(id)

        // NETrafficDirection.any（raw 0）在契约中无对应 case，按入站处理；
        // 实际 FilterDataProvider 只产生 inbound/outbound。
        let trafficDirection: FirewallTrafficDirection =
            direction == .outbound ? .outbound : .inbound

        let event = FirewallEventSnapshot(
            id: id,
            time: .now,
            address: hostname,
            port: port,
            sourceAppIdentifier: id,
            status: shouldAllow ? .allowed : .rejected,
            direction: trafficDirection,
            appId: id
        )

        responseHandler(shouldAllow)

        let events = self.events
        Task {
            do {
                try await events.create(event)
            } catch {
                self.logger.error("存储事件到数据库失败: \(error.localizedDescription)")
            }
        }
    }
}
