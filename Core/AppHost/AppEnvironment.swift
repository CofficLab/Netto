import PluginFirewallDashboard
import Combine
import FactoryNetto
import Foundation
import KernelCore
import OSLog
import PluginFirewall
import PluginShell
import ProviderAppSettings
import ProviderFirewall
import ProviderFirewallEvents
import ProviderShell
import ProviderStore
import SwiftUI

/// App 装配宿主环境 —— 唯一在 App 初始化期装配并缓存核心服务的对象。
///
/// 职责：
/// 1. 通过 `FactoryNetto.makeKernelAsync` 创建 Kernel 并启动插件目录
///    （持久化/设置/事件存储 + App Host 的 UI 贡献插件）。
/// 2. 缓存解析出的契约对象（shell / firewall / events / settings），
///    注入给视图，**视图不再在 body/onAppear/.task 创建或首次启动服务**。
/// 3. 持有纯 UI 状态（`UIProvider` / `AppProvider`），随内核一起注入。
///
/// 约束：
/// - 不持有任何 `*.shared` 单例；生产路径只依赖 Kernel 解析出的契约。
/// - `preview()` 只用于 Xcode 预览（内存 Mock，不落库、不碰系统扩展）。
///
/// 线程/actor：`@MainActor`；`bootstrap()` 必须由 App 启动期调用一次。
@MainActor
final class AppEnvironment: ObservableObject {
    /// 生命周期阶段（Host shell 的启动/失败/运行三态来源）。
    enum Phase: Equatable {
        case booting
        case running
        case failed(String)
    }

    /// 生命周期阶段。
    @Published private(set) var phase: Phase = .booting

    /// 已装配的 Kernel（App 唯一实例；由 Factory 创建）。
    @Published private(set) var kernel: KernelCoreContainer?

    /// Shell 中心（工具栏/设置/窗口/Toast 四契约聚合宿主）。
    @Published private(set) var shell: ShellCenter?

    /// 设置窗口视图（`Window("设置")` 内容，Lumi 式：bootstrap 完成后装配
    /// 一次并缓存，绝不在 body 求值期间装配；仅渲染「通用」入口）。
    @Published private(set) var settingsWindowView: AnyView?

    /// 防火墙契约（缓存，避免视图反复解析；bootstrap 后填充）。
    private(set) var firewall: FirewallProviding?
    /// 事件存储契约（缓存）。
    private(set) var events: FirewallEventsProviding?
    /// 应用设置契约（缓存）。
    private(set) var settings: AppSettingsProviding?
    /// Store 契约（缓存；PluginStore 在 onBoot 注册）。
    private(set) var store: StoreProviding?

    /// 纯 UI 状态（旧 `UIProvider` 语义，App 启动期创建一次）。
    let ui = UIProvider()
    /// 兼容 UI 状态（旧 `AppProvider` 语义；Store 相关视图使用）。
    let appProvider = AppProvider()

    /// 会话起始时间（旧 `EventRepo.sessionStartDate` 语义：App 启动时固定）。
    let sessionStartDate = Date()

    /// 是否已开始引导（避免重复 bootstrap）。
    private var didStart = false

    /// 生产环境初始化：契约对象在 bootstrap 完成后填充。
    private init(
        firewall: FirewallProviding? = nil,
        events: FirewallEventsProviding? = nil,
        settings: AppSettingsProviding? = nil,
        store: StoreProviding? = nil
    ) {
        self.firewall = firewall
        self.events = events
        self.settings = settings
        self.store = store
    }

    /// 创建生产环境并异步引导内核。
    static func make() -> AppEnvironment {
        AppEnvironment()
    }

    /// 预览环境：内存 Mock 契约 + 注册预览贡献的 Shell，phase 直接进入
    /// `.running`（预览不执行 bootstrap；RootView 按 phase 渲染内容）。
    static func preview() -> AppEnvironment {
        let shell = ShellCenter()
        // 注册预览贡献，让预览渲染真实工具栏/设置入口。
        AppHostPlugins.registerPreviewContributions(into: shell)
        let env = AppEnvironment(
            firewall: PreviewFirewall(),
            events: PreviewEvents(),
            settings: PreviewSettings(),
            store: PreviewStore()
        )
        env.shell = shell
        env.phase = .running
        return env
    }

    /// 引导内核（幂等）。失败时进入 `.failed` 阶段并保留错误信息。
    /// - Returns: 是否启动成功。
    func bootstrap() async -> Bool {
        guard !didStart else { return phase == .running }
        didStart = true

        do {
            // 生产目录：基础插件（持久化三件套）+ App Host UI 贡献插件 + PluginFirewall。
            // PluginFirewall 由 App 显式加入（保持 Factory 默认装配可被单元测试
            // 确定性验证；阶段 8 清理旧层后移入 DefaultPluginAssembly）。
            let kernel = try await FactoryNetto.makeKernelAsync(
                additionalPlugins: AppHostPlugins.all(appProvider: appProvider) + [PluginFirewall()]
            )
            guard let shell = kernel.resolveProvider(ShellToolbarProviding.self) as? ShellCenter else {
                self.phase = .failed("Shell 中心未装配")
                return false
            }
            self.kernel = kernel
            self.shell = shell
            self.firewall = kernel.resolveProvider(FirewallProviding.self)
            self.events = kernel.resolveProvider(FirewallEventsProviding.self)
            self.settings = kernel.resolveProvider(AppSettingsProviding.self)
            self.store = kernel.resolveProvider(StoreProviding.self)
            // 设置窗口视图装配一次并缓存（复刻 Lumi：Factory 解析
            // SettingViewProviding → makeSettingView 双栏设置视图）。
            self.settingsWindowView = FactoryNetto.makeSettingsView(kernel: kernel)
            self.phase = .running
            os_log("AppEnvironment 内核启动完成")
            return true
        } catch {
            // 启动失败必须可诊断：错误全文以 public 格式写入统一日志
            // （默认 os_log 插值在 Release 下会被隐私遮蔽为 <private>）。
            os_log(.error, "AppEnvironment 内核启动失败: %{public}@", error.localizedDescription)
            self.phase = .failed(error.localizedDescription)
            return false
        }
    }
}

// MARK: - 预览 Mock

/// 预览用防火墙 Mock：固定 stopped 状态，可启动，命令均为空操作。
@MainActor
private final class PreviewFirewall: FirewallProviding {
    let snapshot = FirewallSnapshot(state: .stopped, lastUpdated: Date())

    func refresh() async {}
    func installSystemExtension() async {}
    func installFilter() async throws {}
    func start() async throws {}
    func stop() async throws {}
    func observe() -> AsyncStream<FirewallSnapshot> {
        AsyncStream { _ in }
    }
}

/// 预览用事件存储 Mock：空库，命令均为空操作。
@MainActor
private final class PreviewEvents: FirewallEventsProviding {
    func fetchPage(_ query: FirewallEventQuery) async throws -> FirewallEventPage {
        FirewallEventPage(events: [], totalCount: 0, page: query.page, pageSize: query.pageSize)
    }

    func count(_ query: FirewallEventCountQuery) async throws -> Int { 0 }
    func totalCount() async throws -> Int { 0 }
    func allAppIds() async throws -> [String] { [] }
    func appIdsSince(_ date: Date) async throws -> [String] { [] }
    func fetchByTimeRange(from: Date, to: Date, appIdentifier: String?) async throws -> [FirewallEventSnapshot] { [] }
    func create(_ event: FirewallEventSnapshot) async throws {}
    func deleteByAppId(_ appId: String) async throws {}
    func deleteAll() async throws -> Int { 0 }
    func cleanupOlderThan(days: Int) async throws -> Int { 0 }
    func triggerMaintenance() async throws -> FirewallMaintenanceResult {
        FirewallMaintenanceResult(isSuccessful: true)
    }

    func observeChanges() -> AsyncStream<FirewallEventChange> {
        AsyncStream { _ in }
    }
}

/// 预览用 Store Mock：无权益、无产品，命令均为空操作。
@MainActor
private final class PreviewStore: StoreProviding {
    var entitlement: StoreEntitlementSnapshot { .none }

    func loadProducts() async throws -> [StoreProductSnapshot] { [] }
    func purchase(_ productID: String) async throws {}
    func restore() async throws {}
    func observeEntitlement() -> AsyncStream<StoreEntitlementSnapshot> {
        AsyncStream { _ in }
    }
}

/// 预览用设置 Mock：空规则库。
@MainActor
private final class PreviewSettings: AppSettingsProviding {
    func fetchAll() async throws -> [AppSettingSnapshot] { [] }
    func find(_ appId: String) async throws -> AppSettingSnapshot? { nil }
    func deniedApps() async throws -> [AppSettingSnapshot] { [] }
    func deniedAppsCount() async throws -> Int { 0 }
    func shouldAllow(_ appId: String) async -> Bool { true }
    func shouldAllowSync(_ appId: String) -> Bool { true }
    func setAllow(_ appId: String) async throws {}
    func setDeny(_ appId: String) async throws {}
    func delete(_ appId: String) async throws {}
    func observeChanges() -> AsyncStream<AppSettingsChange> {
        AsyncStream { _ in }
    }
}
