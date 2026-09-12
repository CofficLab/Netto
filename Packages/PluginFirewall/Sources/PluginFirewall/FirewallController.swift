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
    private var snapshotContinuation: AsyncStream<FirewallSnapshot>.Continuation?
    private var awaitingApproval = false

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
    }

    // MARK: - 状态更新

    private func updateState(_ newState: FirewallState) {
        guard newState != state else { return }
        let oldValue = state
        state = newState
        snapshot = FirewallSnapshot(state: state, lastUpdated: Date())
        logger.info("状态 \(String(describing: oldValue)) -> \(String(describing: newState))")
        snapshotContinuation?.yield(snapshot)
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
        AsyncStream { continuation in
            snapshotContinuation = continuation
            continuation.yield(snapshot)
            continuation.onTermination = { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.snapshotContinuation = nil
                }
            }
        }
    }

    // MARK: - 观察者与 daemon（onReady/onShutdown 生命周期）

    /// 注册过滤器配置变更观察者（旧 setObserver）。
    func startObserving() {
        guard filterObserverToken == nil else { return }
        filterObserverToken = system.addFilterConfigurationObserver { [weak self] enabled in
            self?.updateState(enabled ? .running : .stopped)
        }
    }

    /// daemon 启动（迁移自旧 runDaemon）：
    /// 1. 注册系统扩展工作区观察者（macOS 15.1+）。
    /// 2. 加载过滤器配置（失败仅记录，不阻断）。
    /// 3. 与 Extension 建立 IPC 关联。
    func startDaemon() async {
        system.registerWorkspaceObserver { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                _ = await self.registerIPC()
            }
        }

        do {
            _ = try await system.loadFilterEnabled()
        } catch {
            logger.error("Boot 加载过滤器配置失败: \(error.localizedDescription)")
        }

        let registered = await registerIPC()
        logger.info("IPC 关联 \(registered ? "成功" : "失败")")
    }

    /// 与 Extension 建立 IPC 关联（旧 registerWithProvider）。
    func registerIPC() async -> Bool {
        await ipc.register()
    }

    /// 停止全部外部资源（onShutdown 调用）。
    func shutdown() {
        if let token = filterObserverToken {
            system.removeFilterConfigurationObserver(token)
            filterObserverToken = nil
        }
        system.unregisterWorkspaceObserver()
        ipc.unregister()
        snapshotContinuation = nil
    }

    // MARK: - SystemExtensionRequestHandling

    func systemExtensionActivationCompleted() {
        awaitingApproval = false
        // 旧行为：未就绪态（未安装/需更新/待审批）回落 stopped。
        if state == .systemExtensionNotInstalled
            || state == .systemExtensionNeedsUpdate
            || state == .systemExtensionApprovalNeeded {
            updateState(.stopped)
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

        var currentVersionInstalled: SystemExtensionPropertyInfo?
        var latestVersion: String = ""
        var latestProperty: SystemExtensionPropertyInfo?

        for property in active {
            if property.bundleVersion == currentVersion.version {
                currentVersionInstalled = property
            }
            if property.bundleVersion > latestVersion {
                latestVersion = property.bundleVersion
                latestProperty = property
            }
        }

        if let currentInstalled = currentVersionInstalled {
            // 旧行为：保持现有状态；未激活/卸载中则覆盖。
            var nextState = state
            if currentInstalled.isEnabled == false {
                nextState = .extensionNotActivated
            }
            if currentInstalled.isUninstalling {
                nextState = .systemExtensionNotInstalled
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
