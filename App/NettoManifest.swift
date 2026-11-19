import KernelCore
import LumiFactory
import PluginAbout
import PluginAppSettings
import PluginBrandLogo
import PluginEventStore
import PluginFirewall
import PluginFirewallDashboard
import PluginHostActions
import PluginPersistence
import PluginSettingView
import PluginStore
import PluginThemePack
import ProviderAppSettings
import ProviderFirewall
import ProviderFirewallEvents
import ProviderRootView
import ProviderSettingView
import ProviderShell
import ProviderStore
import ProviderStoreKit
import ProviderToolbar
import ProviderViewEnvironment
import SwiftUI
import WorkbenchRootView
#if os(macOS)
import AppKit
#endif

/// NettoManifest —— TravelMode 的宿主清单与插件供给。
///
/// 装配流水线、窗口壳、状态栏宿主、启动失败归因全部由共享包 `LumiFactory`
/// 解释执行；App 侧只保留真正属于 TravelMode 的差异：
/// 1. `manifest`：品牌身份、窗口 / AX 契约、存储与主题配置、功能开关；
/// 2. `makePlugins()`：稳定顺序的显式插件数组（禁止 ObjC 运行时扫描）；
/// 3. 宿主域接线：ShellCenter 五契约注册、主窗口工具栏 / 内容区接线、
///    窗口路由与主视图 / 菜单栏弹窗的环境注入。
///
/// 根视图是 host provider（基线 `FactoryRootViewProviding`），不再由
/// RootViewPlugin 注册；主内容区是仪表盘 `ContentView`，由 `wireKernel`
/// 直接写入（`skipsSharedRootViewWiring` 关闭共享的空内容接线）。
///
/// 线程/actor：全部方法 `@MainActor`。
@MainActor
enum NettoManifest {

    // MARK: - Root View Configuration

    /// 主窗口根布局：顶部工具栏 + 内容区（与 Wakey / Lumi 同构）。
    nonisolated static let rootViewLayout = RootViewLayoutConfiguration(
        showsToolbar: true,
        emptyStateTitle: "暂无内容"
    )

    // MARK: - Host Manifest

    /// TravelMode 与共享装配引擎之间的全部差异。
    ///
    /// 窗口 id 与 AX 标识是 UI 测试的稳定锚点，一旦发布不可随意更改。
    static var manifest: HostManifest {
        let identity = HostIdentity(
            appName: "TravelMode",
            loggerSubsystem: "com.yueyi.TravelMode",
            mainWindowID: ShellWindowID.main,
            settingsWindowID: ShellWindowID.settings,
            accessibilityPrefix: "netto",
            mainWindowMinimumSize: CGSize(width: 820, height: 560),
            mainWindowDefaultSize: CGSize(width: 1000, height: 760),
            settingsWindowDefaultSize: CGSize(width: 960, height: 560)
        )
        return HostManifest(
            identity: identity,
            makePlugins: { makePlugins() },
            storage: HostStorageConfiguration(
                stateStorePluginID: "com.yueyi.TravelMode.plugin-manager"
            ),
            // 主题选择存储目录沿用旧 `DefaultThemeProviding()` 默认值，
            // 延续用户已选主题（<App Support>/<bundleID>/ThemeManager/）。
            theme: HostThemeConfiguration(storageDirectoryName: "ThemeManager"),
            rootViewLayout: rootViewLayout,
            registerProviders: { kernel in
                // ShellCenter 聚合宿主域五契约（工具栏 / 设置 / 窗口 / 路由 / Toast）。
                // 基线已注册 MenuBar / Logo / Toolbar / SettingView / Theme 等共享
                // Provider，这里只补 App 域的 Shell 契约（HostAction 插件硬依赖
                // SettingsProviding 解析为 ShellCenter）。
                let shell = ShellCenter()
                try kernel.registerProvider(ShellToolbarProviding.self, shell)
                try kernel.registerProvider(SettingsProviding.self, shell)
                try kernel.registerProvider(WindowProviding.self, shell)
                try kernel.registerProvider(WindowRoutingProviding.self, shell)
                try kernel.registerProvider(ProviderShell.ToastProviding.self, shell)
            },
            wireKernel: { kernel in wireKernel(kernel) },
            makeMainView: { kernel in makeMainView(kernel) },
            features: HostFeatures(
                statusBar: statusBarConfiguration(identity: identity),
                opensMainWindowOnLaunch: true,
                // 设置按钮由 wireKernel 自接（NettoToolbarSettings），不走共享按钮。
                showsSettingsToolbarButton: false,
                reopensMainWindowOnActivate: true,
                // 菜单栏 App：关窗后驻留状态栏，不退出。
                quitsWhenLastWindowClosed: false,
                suppressSettingsWindowOnLaunch: true,
                settingsWindowOpenArgument: "-netto-open-settings",
                // 仪表盘依赖大量后代 AX 标识（netto.apps.list / netto.app.row.* 等），
                // 容器级标识会传播遮蔽后代，故关闭并用就绪标记 overlay 提供锚点。
                appliesWindowContentIdentifiers: false,
                usesReadyMarkerOverlays: true,
                // 主内容区是仪表盘 ContentView，由 wireKernel 直接写入；共享接线
                // 注入的空 ContentViewProviding 会挡住仪表盘内容，故关闭。
                skipsSharedRootViewWiring: true
            )
        )
    }

    // MARK: - Status Bar

    /// 状态栏配置：沿用历史 AX 锚点 `netto.menu-bar` 与弹窗菜单行
    /// `netto.menubar.*`；弹窗内容经 `wrapPopup` 注入宿主域环境。
    private static func statusBarConfiguration(identity: HostIdentity) -> HostStatusBarConfiguration {
        HostStatusBarConfiguration(
            statusViewHeight: 20,
            popoverWidth: 300,
            popoverMaximumHeight: 800,
            activatesApplication: true,
            accessibilityIdentifier: "netto.menu-bar",
            wrapPopup: { themed, kernel in injectEnvironment(themed, kernel: kernel) },
            menuItems: [
                HostStatusMenuItem(
                    title: "打开 TravelMode",
                    windowID: identity.mainWindowID,
                    accessibilityIdentifier: "netto.menubar.open-main"
                ),
                HostStatusMenuItem(
                    title: "设置…",
                    windowID: identity.settingsWindowID,
                    accessibilityIdentifier: "netto.menubar.settings"
                ),
                HostStatusMenuItem(
                    title: "退出 TravelMode",
                    accessibilityIdentifier: "netto.menubar.quit",
                    isDestructive: true,
                    action: { NSApp.terminate(nil) }
                ),
            ]
        )
    }

    // MARK: - Post-start Wiring

    /// 启动完成后的宿主域接线（装配期调用一次，贡献字段是 @Published，
    /// 必须在 SwiftUI body 求值期之外写入）。
    private static func wireKernel(_ kernel: KernelCoreContainer) {
        // 主窗口根视图：工具栏（插件贡献的开关 / 筛选 + 右侧设置按钮）+ 仪表盘内容。
        if let rootView = kernel.resolveProvider((any RootViewProviding).self) {
            if let toolbar = kernel.resolveProvider((any ToolbarProviding).self) {
                toolbar.addToolbarItems([NettoToolbarSettings.makeItem()])
                // 不给工具栏容器加 accessibilityIdentifier：SwiftUI 会把容器标识
                // 覆盖到子按钮上，导致设置按钮自身的标识不可查（只依赖各项自身标识）。
                rootView.setToolbarView(toolbar.makeToolbarView())
            }
            rootView.setContentView(AnyView(ContentView()))
        }

        // 插件 / UI 的窗口请求（ShellCenter.requestOpen）统一路由：
        // 设置窗口走标准「打开设置」通知（共享代理负责深链选中 + 开窗），
        // 其余窗口经共享开窗器打开。
        if let shell = kernel.resolveProvider(ShellToolbarProviding.self) as? ShellCenter {
            shell.onRequestOpen = { request in
                if request.windowID == ShellWindowID.settings {
                    var userInfo: [String: Any]?
                    if let entryID = request.entryID {
                        userInfo = [SettingViewNavigation.entryIDUserInfoKey: entryID]
                    }
                    NotificationCenter.default.post(
                        name: SettingViewNavigation.openSettingsNotification,
                        object: nil,
                        userInfo: userInfo
                    )
                } else {
                    HostWindowOpener.shared.openWindow(id: request.windowID)
                }
            }
        }
    }

    // MARK: - Main View

    /// 主视图组装（纯读取）：共享根视图 + 宿主域环境注入。
    ///
    /// 主题桥接 / 全局背景 / 工具栏 placement / 最小尺寸由共享壳
    /// `HostMainContentView` 统一包装，这里只注入仪表盘所需的契约环境。
    /// 首次安装 / 重要版本升级时经 `.task` 触发欢迎窗口（幂等）。
    private static func makeMainView(_ kernel: KernelCoreContainer) -> AnyView {
        let root = kernel.resolveProvider((any RootViewProviding).self)
        let base = root?.makeRootView() ?? AnyView(ContentView())
        return AnyView(
            injectEnvironment(base, kernel: kernel)
                .task { NettoAssembly.welcomeRouter.checkVersionOnce() }
        )
    }

    /// 向视图注入宿主域环境（主窗口与菜单栏弹窗共用同一份值）：
    /// shell / ui / appProvider / firewall / events / settings / store /
    /// sessionStartDate —— 共享工具栏里的防火墙开关、筛选控件与仪表盘内容
    /// 都从这里取依赖。
    private static func injectEnvironment(
        _ content: AnyView,
        kernel: KernelCoreContainer
    ) -> AnyView {
        var view = content
        if let shell = kernel.resolveProvider(ShellToolbarProviding.self) as? ShellCenter {
            view = AnyView(view.environmentObject(shell))
        }
        return AnyView(
            view
                .environmentObject(NettoAssembly.ui)
                .environmentObject(NettoAssembly.appProvider)
                .environment(\.firewallProvider, kernel.resolveProvider(FirewallProviding.self))
                .environment(\.eventsProvider, kernel.resolveProvider(FirewallEventsProviding.self))
                .environment(\.settingsProvider, kernel.resolveProvider(AppSettingsProviding.self))
                .environment(\.storeProvider, kernel.resolveProvider(StoreProviding.self))
                .environment(\.sessionStartDate, NettoAssembly.sessionStartDate)
        )
    }

    // MARK: - Plugin Assembly

    /// 返回显式插件数组（稳定 order、硬依赖、默认启用策略在此声明）。
    ///
    /// 顺序约定：order 值越小越先启动；`persistence` 是最底层基础设施，
    /// `appsettings` / `eventstore` 依赖它；Dashboard 依赖防火墙、设置、事件与 Store。
    /// 根视图由基线 host provider 提供，不再挂载 RootViewPlugin。
    static func makePlugins() -> [any SuperPlugin] {
        [
            BrandLogoPlugin(),        // order 20：向菜单栏贡献品牌图标（LogoProviding）
            PersistencePlugin(),      // order 1：db.sqlite / ModelContainer 唯一所有者
            // 设置窗口外壳（与 Lumi / Wakey 同款）：替换默认
            // DefaultSettingViewProviding，侧边栏顶部渲染 App 图标、名称、版本与构建号。
            PluginSettingView(id: "com.yueyi.TravelMode.plugin.setting-view"), // order 3
            PluginAppSettings(),      // order 10：依赖 persistence
            PluginEventStore(),       // order 10：依赖 persistence
            PluginFirewall(),         // order 30：网络过滤、系统扩展与 IPC
            PluginStore(),            // order 40：StoreKit 服务与权益
            FirewallDashboardPlugin(), // order 60：贡献菜单栏 popover 主面板与工具栏开关 / 筛选
            ThemePackPlugin(id: "com.yueyi.TravelMode.plugin.theme-pack", policy: .enabledByDefault),
            // 「关于」入口（共享远程包 LumiPluginAbout，注入 TravelMode 品牌配置）。
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