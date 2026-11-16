import AppKit
import Foundation
import ProviderViewEnvironment
import KernelCore
import LumiUI
import PluginFirewallDashboard
import PluginHostActions
import ProviderShell
import ProviderAppCatalog
import ProviderAppSettings
import ProviderFirewall
import ProviderFirewallEvents
import ProviderRootView
import ProviderSettingView
import ProviderStore
import ProviderStoreKit
import ProviderTheme
import ProviderToolbar
import ProviderMenuBar
import ProviderLogo
import SwiftUI

/// FactoryNetto —— Netto 唯一静态装配点。
///
/// 职责：
/// 1. `makeKernelAsync()`：创建 KernelCore 容器、注册共享 Provider，并启动
///    `makePlugins()` 返回的显式插件数组；可在 Provider 就绪时安装 AppKit Host。
/// 2. `makePlugins()`：返回稳定顺序的插件数组（阶段 4-7 逐步填充真实插件）。
/// 3. `makeMainView(kernel:)` / `makeStatusBarView(kernel:brandImage:)` /
///    `makeMenuBarPopoverView(kernel:...)` / `makeSettingsView(kernel:)`：
///    装配主窗口视图、状态栏图标、菜单栏面板与设置视图；
///    宿主 App 不得在 `body` 求值期间创建或启动服务。
///
/// Factory 不是第二个 Kernel，也不是万能 Service Locator；它只做装配。
///
/// 线程/actor：全部方法 `@MainActor`。
@MainActor
public enum FactoryNetto {
    /// 使用显式 Provider / Plugin 装配创建同步内核（测试与定制注入点）。
    public static func makeKernel(
        providerAssembly: any ProviderAssembling,
        pluginAssembly: any PluginAssembling,
        additionalPlugins: [any SuperPlugin] = []
    ) throws -> KernelCoreContainer {
        let kernel = KernelCoreContainer()
        try providerAssembly.registerProviders(into: kernel)
        let pluginList = pluginAssembly.makePlugins() + additionalPlugins
        guard !pluginList.isEmpty else {
            // 空目录也推进内核到 running，保证宿主视图可展示。
            try kernel.start(plugins: [])
            return kernel
        }
        try kernel.start(plugins: pluginList)
        resetSettingsSelectionToFirstEntry(in: kernel)
        wireMainWindowRootView(in: kernel)
        return kernel
    }

    /// 设置窗口默认选中 order 最小的入口（回归修复）。
    ///
    /// `addEntries` 会走 `registerEntries`，其"选中为空则锁定为当时列表第一个"
    /// 的语义会让**最先注册入口的插件**意外成为默认选中，与"默认选中第一个"
    /// 的设计意图相悖。全部入口就位后在此重置；本次运行内的用户选择不受影响
    /// （选中态在内存中保留，重启后回到第一个）。
    private static func resetSettingsSelectionToFirstEntry(in kernel: KernelCoreContainer) {
        guard let settings = kernel.resolveProvider((any SettingViewProviding).self),
              let firstID = settings.entries.first?.id,
              settings.selectedEntryID != firstID
        else { return }
        settings.selectEntry(id: firstID)
    }

    /// 异步启动版本（阶段 4 引入 AsyncSuperPlugin 插件后使用）。
    public static func makeKernelAsync(
        providerAssembly: any ProviderAssembling = DefaultProviderAssembly(),
        pluginAssembly: any PluginAssembling = DefaultPluginAssembly(),
        additionalPlugins: [any SuperPlugin] = [],
        onProvidersRegistered: (@MainActor (KernelCoreContainer) -> Void)? = nil
    ) async throws -> KernelCoreContainer {
        let kernel = KernelCoreContainer()
        try providerAssembly.registerProviders(into: kernel)
        // AppKit hosts such as the status item can be installed as soon as the
        // shared providers exist, while the popup itself observes boot progress.
        onProvidersRegistered?(kernel)
        try await kernel.startAsync(plugins: pluginAssembly.makePlugins() + additionalPlugins)
        resetSettingsSelectionToFirstEntry(in: kernel)
        wireMainWindowRootView(in: kernel)
        return kernel
    }

    /// 返回显式插件数组（稳定 order、硬依赖、默认启用策略在此声明）。
    public static func makePlugins() -> [any SuperPlugin] {
        DefaultPluginAssembly().makePlugins()
    }

    /// 创建由 App Target 持有的运行环境，并应用产品默认主题。
    public static func makeAppEnvironment() -> AppEnvironment {
        AppEnvironment.make()
    }

    /// 装配 TravelMode 的窗口场景；窗口内容和生命周期协调逻辑留在 Factory。
    public static func makeAppScenes(environment: AppEnvironment) -> NettoAppScenes {
        NettoAppScenes(environment: environment)
    }

    /// 在没有启动 Kernel 的 SwiftUI 预览中注册 UI 插件贡献。
    public static func registerPreviewContributions(into shell: ShellCenter) {
        HostActionPluginAssembly.registerPreviewContributions(into: shell)
    }

    /// 主窗口根视图接线（对齐 Wakey / Lumi）。
    ///
    /// 根视图插件在内核启动时已注册 `RootViewProviding`；这里在装配期写入
    /// 宿主共享工具栏（含右侧设置按钮）与主内容区。工具栏与内容的贡献字段
    /// 是 `@Published`，必须在 SwiftUI 视图更新期间之外写入，避免
    /// "Publishing changes from within view updates" 告警与丢更新。
    private static func wireMainWindowRootView(in kernel: KernelCoreContainer) {
        guard let rootView = kernel.resolveProvider((any RootViewProviding).self) else { return }

        if let toolbar = kernel.resolveProvider((any ToolbarProviding).self) {
            toolbar.addToolbarItems([NettoToolbarSettings.makeItem()])
            // 不给工具栏容器加 accessibilityIdentifier：SwiftUI 会把容器标识
            // 覆盖到子按钮上，导致设置按钮自身的标识不可查（与 Wakey 一致，
            // 只依赖各项自身的标识）。
            rootView.setToolbarView(AnyView(toolbar.makeToolbarView()))
        }

        rootView.setContentView(AnyView(ContentView()))
    }

    // MARK: - Main View

    /// 在 AppKit Host 中托管主视图，并统一启动态、失败态和运行态切换。
    public static func makeRootView<Content: View>(
        environment: AppEnvironment,
        onRunning: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) -> AnyView {
        AnyView(RootView(environment: environment, onRunning: onRunning, content: content))
    }

    /// 异步创建生产内核并返回完整主视图（默认 UI 状态实例；App 组合根应使用
    /// 注入自身 `AppEnvironment` 持有的 `ui`/`appProvider`/`sessionStartDate`
    /// 的重载，保证单一状态来源）。
    public static func makeMainView() async throws -> AnyView {
        let kernel = try await makeKernelAsync()
        return makeMainView(kernel: kernel)
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
    /// 解析 Shell 与全部 Provider 契约并注入环境后渲染共享根视图
    /// （`RootViewProviding`：工具栏 + 仪表盘内容）；根视图缺失时退回
    /// 仪表盘内容本身。`ui`/`appProvider`/`sessionStartDate` 由调用方持有
    /// （App 组合根 `AppEnvironment` 或本方法默认实例），不在 body 中创建服务。
    public static func makeMainView(
        kernel: KernelCoreContainer,
        ui: UIProvider,
        appProvider: AppProvider,
        sessionStartDate: Date
    ) -> AnyView {
        let shell = kernel.resolveProvider(ShellToolbarProviding.self) as? ShellCenter
        let host = KernelHostRootView(
            kernel: kernel,
            shell: shell,
            ui: ui,
            appProvider: appProvider,
            sessionStartDate: sessionStartDate
        )
        // 与设置窗口一致：把 ThemeProviding 选中的主题桥接到 LumiUI，
        // 让共享工具栏（`@LumiTheme`）使用宿主主题。
        if let theme = kernel.resolveProvider(ThemeProviding.self) {
            return AnyView(ThemeHostingView(theme: theme, content: host))
        }
        return AnyView(host)
    }

    // MARK: - Menu Bar

    /// 状态栏图标视图：插件注入的品牌 Logo + 各插件注入的 `contentItems`。
    ///
    /// 系统菜单栏只由这里绘制一次；品牌图标来自 `LogoProviding` 的最高优先级
    /// `LogoItem`（无插件贡献时退回 App 资源 `brandImage`），状态与文字全部来自
    /// `MenuBarProviding`，Factory 不感知任何具体插件。
    public static func makeStatusBarView(
        kernel: KernelCoreContainer,
        brandImage: Image
    ) -> AnyView {
        guard let menuBar = kernel.resolveProvider(MenuBarProviding.self) else {
            return AnyView(MenuBarBrandMark(image: brandImage).frame(height: 20))
        }
        return AnyView(MenuBarStatusBarView(
            logo: kernel.resolveProvider((any LogoProviding).self),
            provider: menuBar,
            brandImage: brandImage
        ))
    }

    /// 返回由插件注入的菜单栏弹出面板（紧凑型）。
    ///
    /// 分区：上 = 插件贡献的 `popupItems`；下 = App 级动作行
    /// （打开主窗口 / 设置 / 退出）。动作行由宿主提供，避免产品文案进入通用插件包。
    public static func makeMenuBarPopoverView(
        kernel: KernelCoreContainer,
        environment: AppEnvironment,
        onOpenMainWindow: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) -> AnyView {
        AnyView(MenuBarPopoverHost(
            provider: kernel.resolveProvider(MenuBarProviding.self),
            shell: (kernel.resolveProvider(ShellToolbarProviding.self) as? ShellCenter) ?? ShellCenter(),
            firewall: kernel.resolveProvider(FirewallProviding.self),
            events: kernel.resolveProvider(FirewallEventsProviding.self),
            settings: kernel.resolveProvider(AppSettingsProviding.self),
            store: kernel.resolveProvider(StoreProviding.self),
            ui: environment.ui,
            appProvider: environment.appProvider,
            sessionStartDate: environment.sessionStartDate,
            onOpenMainWindow: onOpenMainWindow,
            onOpenSettings: onOpenSettings,
            onQuit: onQuit
        ))
    }

    /// 装配由 HostActions Package 提供的首次使用引导视图。
    public static func makeWelcomeGuideView() -> AnyView {
        AnyView(WelcomeGuideView())
    }

    // MARK: - Settings View

    /// 异步创建生产内核并返回设置视图。
    public static func makeSettingsView() async throws -> AnyView {
        let kernel = try await makeKernelAsync()
        return makeSettingsView(kernel: kernel)
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
        // 刷新桥：上游 `SettingView` 读取的是非可观察 Provider 的
        // `selectedEntryID`，自身 @State 又从未在 body 读取，导致点击左侧
        // 入口后右侧详情不刷新。桥接层订阅变更并用 `.id()` 强制重建。
        let view = SettingsViewRefreshBridge(provider: settings) {
            settings.makeSettingView()
        }
        // 复刻 Lumi ViewFactory：解析 ThemeProviding 并以主题感知视图包装
        // 设置窗口（切换主题即时同步 LumiUI 全局主题状态）。
        if let theme = kernel.resolveProvider(ThemeProviding.self) {
            return AnyView(ThemeHostingView(theme: theme, content: view))
        }
        return AnyView(view)
    }
}

@MainActor
private struct MenuBarStatusBarView: View {
    let logo: (any LogoProviding)?
    let provider: any MenuBarProviding
    let brandImage: Image

    @StateObject private var refreshModel: MenuBarRefreshModel
    @StateObject private var logoRefreshModel: LogoRefreshModel

    init(logo: (any LogoProviding)?, provider: any MenuBarProviding, brandImage: Image) {
        self.logo = logo
        self.provider = provider
        self.brandImage = brandImage
        _refreshModel = StateObject(wrappedValue: MenuBarRefreshModel(provider: provider))
        _logoRefreshModel = StateObject(wrappedValue: LogoRefreshModel(provider: logo))
    }

    private var items: [MenuBarContribution] {
        provider.contentItems.sorted {
            if $0.order == $1.order { return $0.id < $1.id }
            return $0.order < $1.order
        }
    }

    var body: some View {
        let _ = refreshModel.revision
        let _ = logoRefreshModel.revision
        HStack(spacing: 4) {
            brandMark

            ForEach(items) { item in
                item.makeView()
                    .fixedSize(horizontal: true, vertical: true)
                    .help(item.title)
            }
        }
        .padding(.horizontal, 2)
        .frame(height: 20)
    }

    @ViewBuilder
    private var brandMark: some View {
        if let item = logo?.highestPriorityLogoItem {
            item.makeView(.statusBar)
                .frame(width: 18, height: 18)
        } else {
            MenuBarBrandMark(image: brandImage)
        }
    }
}

/// Logo 刷新桥：`LogoProviding` 不是 `ObservableObject`，用观察者把插件在
/// `onBoot` 期间追加的 Logo 贡献收敛到状态栏视图的一次重绘。
@MainActor
private final class LogoRefreshModel: ObservableObject {
    @Published private(set) var revision = 0
    private var observer: (any LogoObserverHandle)?

    init(provider: (any LogoProviding)?) {
        guard let provider else { return }
        observer = provider.addLogoObserver { [weak self] _ in
            self?.revision &+= 1
        }
    }
}

@MainActor
private struct MenuBarBrandMark: View {
    let image: Image

    var body: some View {
        image
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
    }
}

@MainActor
private struct MenuBarPopoverHost: View {
    let provider: (any MenuBarProviding)?
    let shell: ShellCenter
    let firewall: FirewallProviding?
    let events: FirewallEventsProviding?
    let settings: AppSettingsProviding?
    let store: StoreProviding?
    let ui: UIProvider
    let appProvider: AppProvider
    let sessionStartDate: Date
    let onOpenMainWindow: () -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    var body: some View {
        Group {
            if let provider {
                MenuBarPopoverView(
                    provider: provider,
                    onOpenMainWindow: onOpenMainWindow,
                    onOpenSettings: onOpenSettings,
                    onQuit: onQuit
                )
            } else {
                MenuBarPopoverUnavailable(
                    onOpenMainWindow: onOpenMainWindow,
                    onOpenSettings: onOpenSettings,
                    onQuit: onQuit
                )
            }
        }
        .environmentObject(shell)
        .environmentObject(ui)
        .environmentObject(appProvider)
        .environment(\.firewallProvider, firewall)
        .environment(\.eventsProvider, events)
        .environment(\.settingsProvider, settings)
        .environment(\.storeProvider, store)
        .environment(\.sessionStartDate, sessionStartDate)
        .preferredColorScheme(
            (NSApp?.effectiveAppearance ?? NSAppearance(named: .aqua))?
                .bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .dark : .light
        )
    }
}

@MainActor
private struct MenuBarPopoverView: View {
    let provider: any MenuBarProviding
    let onOpenMainWindow: () -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    @StateObject private var refreshModel: MenuBarRefreshModel

    init(
        provider: any MenuBarProviding,
        onOpenMainWindow: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.provider = provider
        self.onOpenMainWindow = onOpenMainWindow
        self.onOpenSettings = onOpenSettings
        self.onQuit = onQuit
        _refreshModel = StateObject(wrappedValue: MenuBarRefreshModel(provider: provider))
    }

    private var items: [MenuBarContribution] {
        provider.popupItems.sorted {
            if $0.order == $1.order { return $0.id < $1.id }
            return $0.order < $1.order
        }
    }

    var body: some View {
        let _ = refreshModel.revision
        VStack(spacing: 0) {
            if !items.isEmpty {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        item.makeView()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)

                        if item.id != items.last?.id {
                            Divider()
                        }
                    }
                }

                Divider()
            }

            MenuBarActionSection(
                onOpenMainWindow: onOpenMainWindow,
                onOpenSettings: onOpenSettings,
                onQuit: onQuit
            )
        }
        .frame(width: 300)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

/// 菜单栏 Provider 缺失时的降级面板：保留宿主动作，避免用户无法打开主窗口/退出。
@MainActor
private struct MenuBarPopoverUnavailable: View {
    let onOpenMainWindow: () -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("菜单栏功能未装配")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            MenuBarActionSection(
                onOpenMainWindow: onOpenMainWindow,
                onOpenSettings: onOpenSettings,
                onQuit: onQuit
            )
        }
        .frame(width: 300)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

/// Popover 底部 App 级动作行。动作由宿主注入，不进入通用插件包。
@MainActor
private struct MenuBarActionSection: View {
    let onOpenMainWindow: () -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            MenuBarActionRow(
                title: "打开 TravelMode",
                icon: "macwindow",
                color: .accentColor,
                action: perform(onOpenMainWindow)
            )
            .accessibilityIdentifier("netto.menubar.open-main")

            Divider().padding(.leading, 36)

            MenuBarActionRow(
                title: "设置…",
                icon: "gearshape",
                color: .accentColor,
                action: perform(onOpenSettings)
            )
            .accessibilityIdentifier("netto.menubar.settings")

            Divider().padding(.leading, 36)

            MenuBarActionRow(
                title: "退出 TravelMode",
                icon: "power",
                color: .red,
                action: perform(onQuit)
            )
            .accessibilityIdentifier("netto.menubar.quit")
        }
        .padding(.vertical, 8)
    }

    private func perform(_ action: @escaping () -> Void) -> () -> Void {
        {
            dismiss()
            action()
        }
    }
}

@MainActor
private struct MenuBarActionRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(isHovering ? Color.primary : color)
                    .frame(width: 18)

                Text(title)
                    .font(.system(size: 11))
                    .foregroundStyle(isHovering ? Color.primary : Color.secondary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isHovering ? Color.accentColor.opacity(0.16) : .clear)
        .onHover { isHovering = $0 }
    }
}
