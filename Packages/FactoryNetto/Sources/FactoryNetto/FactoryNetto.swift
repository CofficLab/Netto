import Foundation
import KernelCore
import PluginFirewallDashboard
import PluginShell
import ProviderAppCatalog
import ProviderAppSettings
import ProviderFirewall
import ProviderFirewallEvents
import ProviderSettingView
import ProviderShell
import ProviderStore
import ProviderTheme
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

    /// 创建内核并返回完整主视图（默认 UI 状态实例；App 组合根应使用
    /// 注入自身 `AppEnvironment` 持有的 `ui`/`appProvider`/`sessionStartDate`
    /// 的重载，保证单一状态来源）。
    public static func makeMainView() throws -> AnyView {
        try makeMainView(kernel: makeKernel())
    }

    /// 使用已装配的内核返回主视图（默认 UI 状态实例）。
    public static func makeMainView(kernel: KernelCoreContainer) -> AnyView {
        makeMainView(
            kernel: kernel,
            ui: UIProvider(),
            appProvider: AppProvider(),
            sessionStartDate: Date()
        )
    }

    /// 使用已装配的内核返回主视图（主窗口/菜单栏共享同一内核时使用）。
    ///
    /// 解析 Shell 与全部 Provider 契约并注入环境后渲染真实 Dashboard
    /// （`KernelHostRootView` → `ContentView`）；契约缺失时显式失败视图。
    /// `ui`/`appProvider`/`sessionStartDate` 由调用方持有（App 组合根
    /// `AppEnvironment` 或本方法默认实例），不在 body 中创建服务。
    public static func makeMainView(
        kernel: KernelCoreContainer,
        ui: UIProvider,
        appProvider: AppProvider,
        sessionStartDate: Date
    ) -> AnyView {
        let shell = kernel.resolveProvider(ShellToolbarProviding.self) as? ShellCenter
        return AnyView(KernelHostRootView(
            kernel: kernel,
            shell: shell,
            ui: ui,
            appProvider: appProvider,
            sessionStartDate: sessionStartDate
        ))
    }

    // MARK: - Settings View

    /// 创建内核并返回设置视图。
    public static func makeSettingsView() throws -> AnyView {
        try makeSettingsView(kernel: makeKernel())
    }

    /// 使用已装配的内核返回设置视图（共享内核时使用）。
    ///
    /// 复刻 Lumi `ViewFactory.makeSettingsView(kernel:)`：解析
    /// `SettingViewProviding`（Factory 装配注册的 `DefaultSettingViewProviding`，
    /// 插件注入侧边栏入口）并渲染「左侧入口列表 + 右侧详情视图」；
    /// Provider 未装配时返回显式失败视图（不静默退化）。
    public static func makeSettingsView(kernel: KernelCoreContainer) -> AnyView {
        guard let settings = kernel.resolveProvider(SettingViewProviding.self) else {
            return AnyView(BootstrapFailureView(title: "设置 Provider 未装配", message: "SettingViewProviding not registered"))
        }
        let view = settings.makeSettingView()
        // 复刻 Lumi ViewFactory：解析 ThemeProviding 并以主题感知视图包装
        // 设置窗口（切换主题即时同步 LumiUI 全局主题状态）。
        if let theme = kernel.resolveProvider(ThemeProviding.self) {
            return AnyView(ThemeHostingView(theme: theme, content: view))
        }
        return view
    }
}
