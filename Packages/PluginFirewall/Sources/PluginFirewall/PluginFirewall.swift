import Foundation
import KernelCore
import NettoIPCContracts
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
        name: "Firewall",
        version: "1.0",
        policy: .enabledByDefault,
        summary: "网络过滤器 / 系统扩展 / IPC 生命周期所有者"
    )

    private let system: any FirewallSystemAdapting
    private let ipc: any FirewallIPCServing
    private var controller: FirewallController?
    private var promptBridge: PromptUserBridge?

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

        try kernel.registerProvider(controller, for: FirewallProviding.self, owner: id)

        // NSXPC 导出的 AppCommunication 对象：决策请求经桥接跳回主线程。
        let bridge = PromptUserBridge(controller: controller)
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
        controller = nil
    }
}

/// NSXPC 导出的 AppCommunication 实现：把远端回调跳回 MainActor 控制器。
///
/// 线程/actor：普通 NSObject（非隔离）；所有方法立即跳转 MainActor。
final class PromptUserBridge: NSObject, AppCommunication {
    private weak var controller: FirewallController?

    init(controller: FirewallController) {
        self.controller = controller
    }

    nonisolated func promptUser(
        id: String,
        hostname: String,
        port: String,
        direction: NETrafficDirection,
        responseHandler: @escaping @Sendable (Bool) -> Void
    ) {
        Task { @MainActor [weak controller] in
            controller?.handlePrompt(
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
}

/// 过渡期兼容：旧 App 侧 `.firewallNeedApproval` 通知名（Foundation 级）。
extension Notification.Name {
    static let firewallNeedApproval = Notification.Name("firewallNeedApproval")
}
