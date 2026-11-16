import Foundation
import KernelCore
import PluginAppSettings
import PluginEventStore
import PluginFirewall
import PluginFirewallDashboard
import PluginBrandLogo
import PluginHostActions
import PluginPersistence
import PluginRootView
import PluginSettingView
import ProviderShell
import PluginStore
import PluginThemePack
import PluginAbout
import ProviderRootView
import ProviderSettingView
import ProviderTheme
import ProviderToolbar
import ProviderMenuBar
import ProviderLogo

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
        try kernel.registerHostProvider(MenuBarProviding.self, DefaultMenuBarProviding())
        try kernel.registerHostProvider(LogoProviding.self, DefaultLogoProviding())
        try kernel.registerHostProvider((any ToolbarProviding).self, DefaultToolbarProviding())
        try kernel.registerProvider(ShellToolbarProviding.self, shell)
        try kernel.registerProvider(SettingsProviding.self, shell)
        try kernel.registerProvider(WindowProviding.self, shell)
        try kernel.registerProvider(WindowRoutingProviding.self, shell)
        try kernel.registerProvider(ToastProviding.self, shell)
        try kernel.registerProvider(SettingViewProviding.self, DefaultSettingViewProviding())
        try kernel.registerProvider(ThemeProviding.self, DefaultThemeProviding())
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
    /// 主窗口根布局：顶部工具栏 + 内容区（与 Wakey / Lumi 同构）。
    nonisolated static let rootViewLayout = RootViewLayoutConfiguration(
        showsToolbar: true,
        emptyStateTitle: "暂无内容"
    )

    /// 根视图插件品牌配置：插件 id 决定启用状态存储 key，必须保持稳定。
    nonisolated static let rootViewConfiguration = RootViewPluginConfiguration(
        pluginID: "com.yueyi.TravelMode.plugin.root-view",
        pluginName: "根视图",
        pluginDescription: "提供 TravelMode 主窗口的根布局",
        order: -1,
        loggerSubsystem: "com.yueyi.TravelMode.plugin.root-view",
        layout: rootViewLayout
    )

    public init() {}

    public func makePlugins() -> [any SuperPlugin] {
        [
            RootViewPlugin(
                configuration: Self.rootViewConfiguration,
                provider: ConfigurableRootViewProviding(layout: Self.rootViewLayout)
            ),                        // order -1：先于全部内容/工具栏贡献者提供根视图
            BrandLogoPlugin(),        // order 20：向菜单栏贡献品牌图标（LogoProviding）
            PersistencePlugin(),      // order 1：db.sqlite / ModelContainer 唯一所有者
            // 设置窗口外壳（与 Lumi / Wakey 同款）：替换默认
            // `DefaultSettingViewProviding`，侧边栏顶部渲染 App 图标、
            // 名称、版本与构建号，入口列表从标题栏下方开始。
            PluginSettingView(id: "com.yueyi.TravelMode.plugin.setting-view"), // order 3
            PluginAppSettings(),      // order 10：依赖 persistence
            PluginEventStore(),       // order 10：依赖 persistence
            PluginFirewall(),         // order 30：网络过滤、系统扩展与 IPC
            PluginStore(),            // order 40：StoreKit 服务与权益
            FirewallDashboardPlugin(), // order 60：贡献菜单栏 popover 主面板
            ThemePackPlugin(id: "com.yueyi.TravelMode.plugin.theme-pack", policy: .enabledByDefault),
            // 「关于」入口（共享远程包 LumiPluginAbout，注入 TravelMode 品牌配置）。
            // Netto 现已在官网更名为 TravelMode，故官网地址用 travelmode。
            AboutPlugin(
                id: "com.yueyi.TravelMode.plugin.about",
                configuration: AboutConfiguration(
                    officialWebsiteURLString: "https://coffic.cn/travelmode",
                    privacyPolicyURLString: "https://coffic.cn/privacy",
                    termsOfServiceURLString: "https://coffic.cn/terms"
                )
            ),
        ] + HostActionPluginAssembly.makePlugins()
    }
}
