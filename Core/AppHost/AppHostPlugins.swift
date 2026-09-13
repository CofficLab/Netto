import PluginFirewallDashboard
import Foundation
import KernelCore
import PluginShell
import PluginStore
import ProviderAppSettings
import ProviderFirewallEvents
import ProviderSettingView
import ProviderShell
import SwiftUI

/// App Host 的 UI 贡献插件目录（App target 内实现，依赖契约而非旧单例）。
///
/// 替代旧 ObjC 自动注册的 13 个插件：工具栏/设置/窗口贡献全部通过
/// `ShellToolbarProviding` / `SettingsProviding` / `WindowProviding` 注册，
/// Kernel 持有撤回 Token；插件间不直接依赖具体插件类型。
///
/// 生命周期：`onBoot` 解析 Shell 契约并注册贡献；`onUnregister`/`onShutdown`
/// 由 Kernel 按 owner 撤回（ShellCenter.removeXxx(ownedBy:)）。
///
/// 约束：本目录插件不创建任何服务；按钮视图只通过注入的契约环境对象取数据。
@MainActor
enum AppHostPlugins {
    /// 生产目录（顺序即贡献稳定性；order 见各插件）。
    static func all(appProvider: AppProvider) -> [any KernelCore.SuperPlugin] {
        var plugins: [any KernelCore.SuperPlugin] = [
            HostSwitcherPlugin(),
            HostFilterPlugin(),
            HostSettingsPlugin(),
            HostGuidePlugin(),
            PluginStore(),
            HostDataFolderPlugin(),
            HostInstallExtensionPlugin(),
            HostAboutPlugin(),
            HostQuitPlugin(),
        ]
        #if DEBUG
        plugins += [HostDBPlugin(), HostClearLogsPlugin()]
        #endif
        return plugins
    }

    /// 预览贡献：空 Shell 下注册与生产相同的按钮，供 Xcode 预览渲染。
    static func registerPreviewContributions(into shell: ShellCenter) {
        HostSwitcherPlugin().contribute(into: shell)
        HostFilterPlugin().contribute(into: shell)
        HostSettingsPlugin().contribute(into: shell)
        HostGuidePlugin().contribute(into: shell)
        HostDataFolderPlugin().contribute(into: shell)
        HostInstallExtensionPlugin().contribute(into: shell)
        HostAboutPlugin().contribute(into: shell)
        HostQuitPlugin().contribute(into: shell)
        #if DEBUG
        HostClearLogsPlugin().contribute(into: shell)
        #endif
    }
}

// MARK: - 工具栏插件

/// 启动/停止切换器（旧 Switcher 插件；left 位置，order 10）。
@MainActor
final class HostSwitcherPlugin: KernelCore.SuperPlugin {
    let id = "switcher"
    var order: Int { 10 }
    var dependencies: [String] { [] }
    let metadata = KernelCore.PluginMetadata(name: "Switcher", version: "1.0", policy: .enabledByDefault)

    init() {}

    func onBoot(kernel: KernelCoreContainer) throws {
        let shell = try kernel.requireProvider(ShellToolbarProviding.self) as? ShellCenter
        guard let shell else { throw KernelCoreError.providerNotFound(type: "ShellCenter") }
        contribute(into: shell)
    }

    func contribute(into shell: ShellCenter) {
        shell.registerToolbar(ToolbarContribution(
            id: "switcher",
            position: .left,
            order: 10,
            ownerPluginID: id
        ) {
            AnyView(TileSwitcher())
        })
    }
}

/// 应用过滤器（旧 Filter 插件；center 位置，order 20）。
@MainActor
final class HostFilterPlugin: KernelCore.SuperPlugin {
    let id = "filter"
    var order: Int { 20 }
    var dependencies: [String] { [] }
    let metadata = KernelCore.PluginMetadata(name: "Filter", version: "1.0", policy: .enabledByDefault)

    init() {}

    func onBoot(kernel: KernelCoreContainer) throws {
        let shell = try kernel.requireProvider(ShellToolbarProviding.self) as? ShellCenter
        guard let shell else { throw KernelCoreError.providerNotFound(type: "ShellCenter") }
        contribute(into: shell)
    }

    func contribute(into shell: ShellCenter) {
        shell.registerToolbar(ToolbarContribution(
            id: "filter",
            position: .center,
            order: 20,
            ownerPluginID: id
        ) {
            AnyView(TileFilter())
        })
    }
}


/// 使用引导入口（旧 GuideButton 插件；settings 入口，order 45）。
/// 打开欢迎引导窗口：复用旧 BtnGuide 视图，保留 .shouldOpenWelcomeWindow
/// App 内信号（TheApp 监听并打开欢迎 Window，行为与旧版一致）。
@MainActor
final class HostGuidePlugin: KernelCore.SuperPlugin {
    let id = "guide"
    var order: Int { 45 }
    var dependencies: [String] { [] }
    let metadata = KernelCore.PluginMetadata(name: "Guide", version: "1.0", policy: .enabledByDefault)

    init() {}

    func onBoot(kernel: KernelCoreContainer) throws {
        let shell = try kernel.requireProvider(SettingsProviding.self) as? ShellCenter
        guard let shell else { throw KernelCoreError.providerNotFound(type: "ShellCenter") }
        contribute(into: shell)
    }

    func contribute(into shell: ShellCenter) {
        shell.registerEntry(SettingsEntry(
            id: "guide",
            order: 45,
            ownerPluginID: id
        ) {
            AnyView(BtnGuide())
        })
    }
}

/// 数据库调试入口（旧 DBPlugin；仅 DEBUG）。
/// 自 v3 起不再注册主窗口工具栏按钮，改为向 `SettingViewProviding`
/// 注入「数据库」设置入口（复刻 Lumi 插件向设置注入入口的模式）；
/// 详情视图 `DBDatabaseDetailView` 通过 onBoot 解析的契约直接注入
/// `FirewallEventsProviding` / `AppSettingsProviding`，不依赖视图环境。
@MainActor
final class HostDBPlugin: KernelCore.SuperPlugin {
    let id = "db"
    var order: Int { 20 }
    var dependencies: [String] { [] }
    let metadata = KernelCore.PluginMetadata(name: "DB", version: "1.0", policy: .enabledByDefault)

    init() {}

    func onBoot(kernel: KernelCoreContainer) throws {
        // 设置视图未注册时优雅降级（不阻塞内核启动）。
        guard let settingsView = kernel.resolveProvider(SettingViewProviding.self) else {
            return
        }
        let events = kernel.resolveProvider(FirewallEventsProviding.self)
        let settings = kernel.resolveProvider(AppSettingsProviding.self)
        settingsView.addEntries([
            SettingEntryItem(id: "database", title: "数据库", systemImage: "cylinder.split.1x2", order: 40) {
                DBDatabaseDetailView(events: events, settings: settings)
            },
        ])
    }

    func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider(SettingViewProviding.self)?
            .removeEntries(ids: ["database"])
    }
}

// MARK: - 设置入口插件

/// 打开 macOS 系统设置（旧 SettingButton 插件；order 30）。
/// 插件 ID 用 `host-settings`：`appsettings` 已被 DefaultPluginAssembly 中的
/// PluginAppSettings（Package 插件）占用，重复 ID 会被 KernelCore 拒绝。
@MainActor
final class HostSettingsPlugin: KernelCore.SuperPlugin {
    let id = "host-settings"
    var order: Int { 30 }
    var dependencies: [String] { [] }
    let metadata = KernelCore.PluginMetadata(name: "AppSettings", version: "1.0", policy: .enabledByDefault)

    init() {}

    func onBoot(kernel: KernelCoreContainer) throws {
        let shell = try kernel.requireProvider(SettingsProviding.self) as? ShellCenter
        guard let shell else { throw KernelCoreError.providerNotFound(type: "ShellCenter") }
        contribute(into: shell)
        // 设置窗口入口注入（复刻 Lumi PluginSettingView 模式：插件在 onBoot
        // 向 SettingViewProviding 注入 SettingEntryItem，Factory 装配的设置
        // 窗口渲染「左侧入口列表 + 右侧详情视图」）。
        if let settingsView = kernel.resolveProvider(SettingViewProviding.self) {
            settingsView.addEntries([
                SettingEntryItem(id: "general", title: "通用", systemImage: "gearshape", order: 5) {
                    GeneralSettingsView()
                },
            ])
        }
    }

    func contribute(into shell: ShellCenter) {
        // 打开 macOS 系统设置（旧 SettingButton 插件行为，设置面板使用）。
        shell.registerEntry(SettingsEntry(
            id: "appsettings",
            order: 30,
            ownerPluginID: id
        ) {
            AnyView(BtnSetting())
        })
    }
}

/// 清空日志（旧 ClearLogsButton 插件；仅 DEBUG，order 40）。
@MainActor
final class HostClearLogsPlugin: KernelCore.SuperPlugin {
    let id = "clearlogs"
    var order: Int { 40 }
    var dependencies: [String] { [] }
    let metadata = KernelCore.PluginMetadata(name: "ClearLogs", version: "1.0", policy: .enabledByDefault)

    init() {}

    func onBoot(kernel: KernelCoreContainer) throws {
        let shell = try kernel.requireProvider(SettingsProviding.self) as? ShellCenter
        guard let shell else { throw KernelCoreError.providerNotFound(type: "ShellCenter") }
        contribute(into: shell)
    }

    func contribute(into shell: ShellCenter) {
        shell.registerEntry(SettingsEntry(
            id: "clearlogs",
            order: 40,
            ownerPluginID: id
        ) {
            AnyView(BtnClearLogs())
        })
    }
}

/// 打开数据目录（旧 DataFolderButton 插件；order 50）。
@MainActor
final class HostDataFolderPlugin: KernelCore.SuperPlugin {
    let id = "datafolder"
    var order: Int { 50 }
    var dependencies: [String] { [] }
    let metadata = KernelCore.PluginMetadata(name: "DataFolder", version: "1.0", policy: .enabledByDefault)

    init() {}

    func onBoot(kernel: KernelCoreContainer) throws {
        let shell = try kernel.requireProvider(SettingsProviding.self) as? ShellCenter
        guard let shell else { throw KernelCoreError.providerNotFound(type: "ShellCenter") }
        contribute(into: shell)
    }

    func contribute(into shell: ShellCenter) {
        shell.registerEntry(SettingsEntry(
            id: "datafolder",
            order: 50,
            ownerPluginID: id
        ) {
            AnyView(BtnOpenDataFolder())
        })
    }
}

/// 安装系统扩展（旧 InstallExtensionButton 插件；order 60）。
@MainActor
final class HostInstallExtensionPlugin: KernelCore.SuperPlugin {
    let id = "installextension"
    var order: Int { 60 }
    var dependencies: [String] { [] }
    let metadata = KernelCore.PluginMetadata(name: "InstallExtension", version: "1.0", policy: .enabledByDefault)

    init() {}

    func onBoot(kernel: KernelCoreContainer) throws {
        let shell = try kernel.requireProvider(SettingsProviding.self) as? ShellCenter
        guard let shell else { throw KernelCoreError.providerNotFound(type: "ShellCenter") }
        contribute(into: shell)
    }

    func contribute(into shell: ShellCenter) {
        shell.registerEntry(SettingsEntry(
            id: "installextension",
            order: 60,
            ownerPluginID: id
        ) {
            AnyView(BtnInstallExtension())
        })
    }
}

/// 关于（旧 AboutButton 插件；order 70）。
@MainActor
final class HostAboutPlugin: KernelCore.SuperPlugin {
    let id = "about"
    var order: Int { 70 }
    var dependencies: [String] { [] }
    let metadata = KernelCore.PluginMetadata(name: "About", version: "1.0", policy: .enabledByDefault)

    init() {}

    func onBoot(kernel: KernelCoreContainer) throws {
        let shell = try kernel.requireProvider(SettingsProviding.self) as? ShellCenter
        guard let shell else { throw KernelCoreError.providerNotFound(type: "ShellCenter") }
        contribute(into: shell)
    }

    func contribute(into shell: ShellCenter) {
        shell.registerEntry(SettingsEntry(
            id: "about",
            order: 70,
            ownerPluginID: id
        ) {
            AnyView(BtnAbout())
        })
    }
}

/// 退出（旧 QuitButton 插件；order 80）。
@MainActor
final class HostQuitPlugin: KernelCore.SuperPlugin {
    let id = "quit"
    var order: Int { 80 }
    var dependencies: [String] { [] }
    let metadata = KernelCore.PluginMetadata(name: "Quit", version: "1.0", policy: .enabledByDefault)

    init() {}

    func onBoot(kernel: KernelCoreContainer) throws {
        let shell = try kernel.requireProvider(SettingsProviding.self) as? ShellCenter
        guard let shell else { throw KernelCoreError.providerNotFound(type: "ShellCenter") }
        contribute(into: shell)
    }

    func contribute(into shell: ShellCenter) {
        shell.registerEntry(SettingsEntry(
            id: "quit",
            order: 80,
            ownerPluginID: id
        ) {
            AnyView(BtnQuit())
        })
    }
}
