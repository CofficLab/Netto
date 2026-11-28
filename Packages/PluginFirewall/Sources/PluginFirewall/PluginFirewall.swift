import Foundation
import KernelCore
import NetpauseIPCContracts
import NetworkExtension
import ProviderAppSettings
import ProviderFirewall
import ProviderFirewallEvents

/// 防火墙插件 —— NEFilterManager / 系统扩展 / IPC adapter / observer / daemon
/// 的唯一拥有者（迁移自旧 `FirewallService` 全家）。
///
/// 生命周期：
/// - onBoot：解析 AppSettings + FirewallEvents（硬依赖），创建控制器与
///   AppCommunication 桥，注册 `FirewallProviding`。
/// - onReadyAsync：注册过滤器配置观察者、启动 daemon（工作区观察者 +
///   加载过滤器配置 + 与 Extension 建立 IPC 关联）、刷新初始状态。
/// - onShutdownAsync：移除观察者、注销工作区观察者、断开 IPC。
///
/// 线程/actor：`@MainActor`；系统回调经适配器桥接回主线程。
@MainActor
public final class PluginFirewall: AsyncSuperPlugin {
    public let id = "firewall"
    public var order: Int { 30 }
    public var dependencies: [String] { ["persistence", "appsettings", "eventstore"] }
    public let metadata = PluginMetadata(
        id: "firewall",
        name: "Firewall",
        description: String(localized: "Owns the network filter, system extension, and IPC lifecycle"),
        version: "1.0",
        policy: .enabledByDefault
    )

    private let system: any FirewallSystemAdapting
    private let ipc: any FirewallIPCServing
    private var controller: FirewallController?
    private var promptBridge: PromptUserBridge?
    private var speedMonitor: AppNetworkSpeedMonitor?

    /// 生产装配：使用真实系统与 NSXPC 适配器。
    public init() {
        let bundle = FirewallExtensionBundle.load()
        self.system = SystemFirewallAdapter(extensionBundle: bundle)
        self.ipc = NSXPCFirewallIPCAdapter(extensionBundle: bundle)
    }

    /// 测试装配：注入 Mock 系统/IPC 适配器（内部协议类型，仅模块内可用）。
    init(system: any FirewallSystemAdapting, ipc: any FirewallIPCServing) {
        self.system = system
        self.ipc = ipc
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        let settings = try kernel.requireProvider(AppSettingsProviding.self)
        let events = try kernel.requireProvider(FirewallEventsProviding.self)

        let controller = FirewallController(system: system, ipc: ipc, settings: settings, events: events)
        self.controller = controller
        system.setRequestHandler(controller)

        try kernel.registerProvider(FirewallProviding.self, controller)

        // 应用实时网速：Extension 每秒上报字节增量，监控器负责速率与平滑。
        let speedMonitor = AppNetworkSpeedMonitor()
        self.speedMonitor = speedMonitor
        try kernel.registerProvider(NetworkSpeedProviding.self, speedMonitor)

        // NSXPC 导出的 AppCommunication 对象：决策请求经桥接跳回主线程。
        let bridge = PromptUserBridge(controller: controller, speedMonitor: speedMonitor)
        self.promptBridge = bridge
        ipc.exportedAppCommunication = bridge
    }

    public func onReadyAsync(kernel: KernelCoreContainer) async throws {
        guard let controller else { return }
        controller.startObserving()
        await controller.startDaemon()
        await controller.refresh()
    }

    public func onShutdownAsync(kernel: KernelCoreContainer) async throws {
        controller?.shutdown()
        system.setRequestHandler(nil)
        promptBridge = nil
        speedMonitor = nil
        controller = nil
    }
}

/// NSXPC 导出的 AppCommunication 实现：把远端回调跳回 MainActor 控制器。
///
/// 线程/actor：普通 NSObject（非隔离）；所有方法立即跳转 MainActor。
final class PromptUserBridge: NSObject, AppCommunication {
    private weak var controller: FirewallController?
    private weak var speedMonitor: AppNetworkSpeedMonitor?

    init(controller: FirewallController?, speedMonitor: AppNetworkSpeedMonitor? = nil) {
        self.controller = controller
        self.speedMonitor = speedMonitor
    }

    nonisolated func promptUser(
        id: String,
        hostname: String,
        port: String,
        direction: NETrafficDirection,
        responseHandler: @escaping @Sendable (Bool) -> Void
    ) {
        Task { @MainActor [weak controller] in
            guard let controller else {
                // 控制器已随插件关闭销毁：必须回复默认裁决，否则扩展会一直
                // 暂停这条流（默认放行与应用默认策略保持一致）。
                responseHandler(true)
                return
            }
            controller.handlePrompt(
                id: id,
                hostname: hostname,
                port: port,
                direction: direction,
                responseHandler: responseHandler
            )
        }
    }

    nonisolated func needApproval() {
        Task { @MainActor in
            // 过渡期通知适配器：与旧 App 的 `.firewallNeedApproval` 兼容。
            NotificationCenter.default.post(name: .firewallNeedApproval, object: nil)
        }
    }

    nonisolated func extensionLog(_ words: String) {}

    nonisolated func reportNetworkTraffic(_ samples: NSArray) {
        // 先在本线程把 NSDictionary 转成 Sendable 值类型，再跳回 MainActor。
        let parsed: [AppNetworkSpeedMonitor.Sample] = samples.compactMap { element in
            guard let dict = element as? [String: Any],
                  let appId = dict["appId"] as? String,
                  !appId.isEmpty else { return nil }
            let bytesIn = (dict["bytesIn"] as? NSNumber)?.doubleValue ?? 0
            let bytesOut = (dict["bytesOut"] as? NSNumber)?.doubleValue ?? 0
            let elapsed = (dict["elapsed"] as? NSNumber)?.doubleValue ?? 1
            return AppNetworkSpeedMonitor.Sample(
                appId: appId,
                bytesIn: bytesIn,
                bytesOut: bytesOut,
                elapsed: elapsed
            )
        }
        Task { @MainActor [weak controller, weak speedMonitor] in
            // 周期上报（空闲时为空数组）是扩展存活的唯一可靠信号：
            // 运行中收不到上报说明过滤器会话没有起来。
            controller?.noteExtensionHeartbeat()
            speedMonitor?.ingest(parsed)
        }
    }
}

/// 过渡期兼容：旧 App 侧 `.firewallNeedApproval` 通知名（Foundation 级）。
extension Notification.Name {
    static let firewallNeedApproval = Notification.Name("firewallNeedApproval")
}
