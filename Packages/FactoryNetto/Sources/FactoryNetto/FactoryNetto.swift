import Foundation
import KernelCore
import PluginShell
import ProviderAppCatalog
import ProviderAppSettings
import ProviderFirewall
import ProviderFirewallEvents
import ProviderShell
import ProviderStore
import SwiftUI

/// FactoryNetto —— Netto 唯一静态装配点。
///
/// 职责：
/// 1. `makeKernel()`：创建 KernelCore 容器，注册 Factory 拥有的共享 Provider
///    （ShellCenter），并原子启动 `makePlugins()` 返回的显式插件数组。
/// 2. `makePlugins()`：返回稳定顺序的插件数组（阶段 4-7 逐步填充真实插件）。
/// 3. `makeMainView(kernel:)` / `makeSettingsView(kernel:)`：一次性装配并缓存
///    主视图与设置视图，宿主 App 不得在 `body` 求值期间重复装配。
///
/// Factory 不是第二个 Kernel，也不是万能 Service Locator；它只做装配。
///
/// 线程/actor：全部方法 `@MainActor`。
@MainActor
public enum FactoryNetto {
    /// 创建内核并原子启动默认插件目录。
    ///
    /// - Throws: 注册失败、插件依赖校验失败或插件启动失败。
    public static func makeKernel(
        additionalPlugins: [any SuperPlugin] = []
    ) throws -> KernelCoreContainer {
        try makeKernel(
            providerAssembly: DefaultProviderAssembly(),
            pluginAssembly: DefaultPluginAssembly(),
            additionalPlugins: additionalPlugins
        )
    }

    /// 使用宿主提供的 Provider / Plugin 装配创建内核（测试与定制注入点）。
    public static func makeKernel(
        providerAssembly: any ProviderAssembling,
        pluginAssembly: any PluginAssembling,
        additionalPlugins: [any SuperPlugin] = []
    ) throws -> KernelCoreContainer {
        let kernel = KernelCoreContainer()
        try providerAssembly.registerProviders(into: kernel)
        let plugins = pluginAssembly.makePlugins() + additionalPlugins
        guard !plugins.isEmpty else {
            // 空目录也推进内核到 running，保证宿主视图可展示。
            try kernel.start(plugins: [])
            return kernel
        }
        try kernel.start(plugins: plugins)
        return kernel
    }

    /// 异步启动版本（阶段 4 引入 AsyncSuperPlugin 插件后使用）。
    public static func makeKernelAsync(
        providerAssembly: any ProviderAssembling = DefaultProviderAssembly(),
        pluginAssembly: any PluginAssembling = DefaultPluginAssembly(),
        additionalPlugins: [any SuperPlugin] = []
    ) async throws -> KernelCoreContainer {
        let kernel = KernelCoreContainer()
        try providerAssembly.registerProviders(into: kernel)
        try await kernel.startAsync(plugins: pluginAssembly.makePlugins() + additionalPlugins)
        return kernel
    }

    /// 返回显式插件数组（稳定 order、硬依赖、默认启用策略在此声明）。
    public static func makePlugins() -> [any SuperPlugin] {
        DefaultPluginAssembly().makePlugins()
    }

    // MARK: - Main View

    /// 创建内核并返回完整主视图。
    public static func makeMainView() throws -> AnyView {
        try makeMainView(kernel: makeKernel())
    }

    /// 使用已装配的内核返回主视图（主窗口/菜单栏共享同一内核时使用）。
    ///
    /// Shell 中心在装配时解析一次并传入视图，避免在 body 中解析/创建服务。
    public static func makeMainView(kernel: KernelCoreContainer) -> AnyView {
        let shell = kernel.resolveProvider(ShellToolbarProviding.self) as? ShellCenter
        return AnyView(KernelHostRootView(kernel: kernel, shell: shell))
    }

    // MARK: - Settings View

    /// 创建内核并返回设置视图。
    public static func makeSettingsView() throws -> AnyView {
        try makeSettingsView(kernel: makeKernel())
    }

    /// 使用已装配的内核返回设置视图（共享内核时使用）。
    public static func makeSettingsView(kernel: KernelCoreContainer) -> AnyView {
        let settings = kernel.resolveProvider(SettingsProviding.self) as? ShellCenter
        return AnyView(SettingsHostView(kernel: kernel, settings: settings))
    }
}
