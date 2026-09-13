import Foundation
import KernelCore
import PluginAppSettings
import PluginEventStore
import PluginFirewall
import PluginFirewallDashboard
import PluginHostActions
import PluginAgentRules
import PluginPersistence
import ProviderShell
import PluginStore
import PluginThemePack
import ProviderSettingView
import ProviderTheme
import ProviderMenuBar

/// Provider 装配协议：把 Factory 拥有的共享 Provider 实现注册进 Kernel。
///
/// 默认实现注册 `ShellCenter`（Shell 四个契约）；宿主测试可注入 Mock 装配。
@MainActor
public protocol ProviderAssembling {
    func registerProviders(into kernel: KernelCoreContainer) throws
}

/// 默认 Provider 装配：创建并注册 ShellCenter 与设置视图 Provider。
///
/// 复刻 Lumi `ProviderFactory`：`SettingViewProviding` 由 Factory 的
/// Provider 装配注册（`DefaultSettingViewProviding`），插件在 onBoot 注入
/// 侧边栏入口，App 通过 `makeSettingsView` 解析并渲染设置窗口。
@MainActor
public struct DefaultProviderAssembly: ProviderAssembling {
    public init() {}

    public func registerProviders(into kernel: KernelCoreContainer) throws {
        let shell = ShellCenter()
        try kernel.registerProvider(DefaultMenuBarProviding(), for: MenuBarProviding.self)
        try kernel.registerProvider(shell, for: ShellToolbarProviding.self)
        try kernel.registerProvider(shell, for: SettingsProviding.self)
        try kernel.registerProvider(shell, for: WindowProviding.self)
        try kernel.registerProvider(shell, for: ToastProviding.self)
        try kernel.registerProvider(DefaultSettingViewProviding(), for: SettingViewProviding.self)
        try kernel.registerProvider(DefaultThemeProviding(), for: ThemeProviding.self)
    }
}

/// 插件装配协议：显式返回插件数组（稳定顺序，禁止 ObjC 运行时扫描）。
@MainActor
public protocol PluginAssembling {
    func makePlugins() -> [any SuperPlugin]
}

/// 默认插件装配：Factory 统一拥有基础设施、业务服务与主面板插件。
///
/// 顺序约定：order 值越小越先启动；`persistence` 是最底层基础设施，
/// `appsettings` / `eventstore` 依赖它；Dashboard 依赖防火墙、设置、事件与 Store。
@MainActor
public struct DefaultPluginAssembly: PluginAssembling {
    public init() {}

    public func makePlugins() -> [any SuperPlugin] {
        [
            PersistencePlugin(),      // order 1：db.sqlite / ModelContainer 唯一所有者
            PluginAppSettings(),      // order 10：依赖 persistence
            PluginEventStore(),       // order 10：依赖 persistence
            PluginFirewall(),         // order 30：网络过滤、系统扩展与 IPC
            PluginStore(),            // order 40：StoreKit 服务与权益
            FirewallDashboardPlugin(), // order 60：贡献菜单栏 popover 主面板
            AgentRulesPlugin(),       // order 70：向工具栏注入规则按钮 + popover
            ThemePackPlugin(),        // order 100：复刻 Lumi 主题包（注册 19 主题 + 外观入口）
        ] + HostActionPluginAssembly.makePlugins()
    }
}
