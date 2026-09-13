import KernelCore
import ProviderShell
import SwiftUI

/// Agent 规则管理插件：向工具栏注入规则按钮 + popover。
///
/// 生命周期：`onBoot` 解析 Shell 契约并注册贡献；`onUnregister`/`onShutdown`
/// 由 Kernel 按 owner 撤回（ShellCenter.removeToolbar(ownedBy:)）。
@MainActor
public final class AgentRulesPlugin: SuperPlugin {
    public let id = "agent-rules"
    public let order = 70
    public let dependencies: [String] = []
    public let metadata = PluginMetadata(
        name: "Agent Rules",
        version: "1.0",
        policy: .enabledByDefault,
        summary: "向工具栏注入规则按钮 + popover"
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        try contribute(to: kernel)
    }

    public func onEnable(kernel: KernelCoreContainer) async throws {
        try contribute(to: kernel)
    }

    public func onDisable(kernel: KernelCoreContainer) async throws {
        kernel.resolveProvider(ShellToolbarProviding.self)?.removeToolbar(ownedBy: id)
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider(ShellToolbarProviding.self)?.removeToolbar(ownedBy: id)
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider(ShellToolbarProviding.self)?.removeToolbar(ownedBy: id)
    }

    private func contribute(to kernel: KernelCoreContainer) throws {
        let toolbar = try kernel.requireProvider(ShellToolbarProviding.self)
        Self.registerPreviewContributions(into: toolbar)
    }

    public static func registerPreviewContributions(into toolbar: ShellToolbarProviding) {
        toolbar.registerToolbar(ToolbarContribution(
            id: "agent-rules",
            position: .right,
            order: 30,
            ownerPluginID: "agent-rules"
        ) {
            AnyView(BtnAgentRules())
        })
    }
}
