import Foundation
import KernelCore
import ProviderSettingView
import ProviderShell
import Testing
@testable import PluginHostActions

// MARK: - 测试脚手架

/// 依赖占位插件：用生产 id 满足 Kernel 的依赖解析，不注册任何契约。
@MainActor
private final class PlaceholderPlugin: SuperPlugin {
    let id: String
    var order: Int { 0 }
    var dependencies: [String] { [] }
    let metadata: PluginMetadata

    init(id: String) {
        self.id = id
        self.metadata = PluginMetadata(id: id, name: id, version: "1.0", policy: .enabledByDefault)
    }

    func onBoot(kernel: KernelCoreContainer) throws {}
}

/// 预置 ShellCenter 与设置视图 Provider 的内核。
@MainActor
private enum HostEnv {
    static let dependencyIDs = ["persistence", "appsettings", "eventstore", "firewall"]

    static func placeholders() -> [any SuperPlugin] {
        dependencyIDs.map(PlaceholderPlugin.init(id:))
    }

    /// 只注册 Shell 契约（不注册设置视图）。
    static func makeShellOnlyKernel() throws -> KernelCoreContainer {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider(SettingsProviding.self, ShellCenter())
        return kernel
    }

    /// 同时注册 Shell 与设置视图契约。
    static func makeKernelWithSettingView() throws -> (KernelCoreContainer, DefaultSettingViewProviding) {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider(SettingsProviding.self, ShellCenter())
        let settingView = DefaultSettingViewProviding()
        try kernel.registerProvider(SettingViewProviding.self, settingView)
        return (kernel, settingView)
    }
}

// MARK: - 测试

/// 需要 Shell 契约的插件在缺少契约时必须失败。
///
/// 各插件的 `onBoot` 都有 `guard let shell else { throw ... }`，
/// 既有测试只覆盖了排序最靠前的那一个，这里逐个插件锁定。
@MainActor
@Suite("Host 插件缺少 Shell 契约")
struct HostPluginRequiresShellTests {

    @Test("引导插件缺少 Shell 契约时抛错")
    func guideRequiresShell() {
        let kernel = KernelCoreContainer()
        #expect(throws: (any Error).self) {
            try kernel.start(plugins: [HostGuidePlugin()])
        }
        #expect(kernel.lifecycleState == .failed)
    }

    @Test("通用设置插件缺少 Shell 契约时抛错")
    func settingsRequiresShell() {
        let kernel = KernelCoreContainer()
        #expect(throws: (any Error).self) {
            try kernel.start(plugins: [HostSettingsPlugin()])
        }
        #expect(kernel.lifecycleState == .failed)
    }

    @Test("清空日志插件缺少 Shell 契约时抛错")
    func clearLogsRequiresShell() {
        let kernel = KernelCoreContainer()
        #expect(throws: (any Error).self) {
            try kernel.start(plugins: HostEnv.placeholders() + [HostClearLogsPlugin()])
        }
        #expect(kernel.lifecycleState == .failed)
    }

    @Test("数据目录插件缺少 Shell 契约时抛错")
    func dataFolderRequiresShell() {
        let kernel = KernelCoreContainer()
        #expect(throws: (any Error).self) {
            try kernel.start(plugins: HostEnv.placeholders() + [HostDataFolderPlugin()])
        }
        #expect(kernel.lifecycleState == .failed)
    }

    @Test("安装扩展插件缺少 Shell 契约时抛错")
    func installExtensionRequiresShell() {
        let kernel = KernelCoreContainer()
        #expect(throws: (any Error).self) {
            try kernel.start(plugins: HostEnv.placeholders() + [HostInstallExtensionPlugin()])
        }
        #expect(kernel.lifecycleState == .failed)
    }

    @Test("关于插件缺少 Shell 契约时抛错")
    func aboutRequiresShell() {
        let kernel = KernelCoreContainer()
        #expect(throws: (any Error).self) {
            try kernel.start(plugins: [HostAboutPlugin()])
        }
        #expect(kernel.lifecycleState == .failed)
    }

    @Test("退出插件缺少 Shell 契约时抛错")
    func quitRequiresShell() {
        let kernel = KernelCoreContainer()
        #expect(throws: (any Error).self) {
            try kernel.start(plugins: [HostQuitPlugin()])
        }
        #expect(kernel.lifecycleState == .failed)
    }
}

/// 设置视图契约存在时的注入路径。
@MainActor
@Suite("Host 插件注入设置视图")
struct HostPluginSettingViewTests {

    @Test("通用设置插件向设置视图注入「通用」入口")
    func settingsPluginInjectsGeneralEntry() throws {
        let (kernel, settingView) = try HostEnv.makeKernelWithSettingView()

        try kernel.start(plugins: HostEnv.placeholders() + [HostSettingsPlugin()])

        let entry = settingView.entries.first { $0.id == "general" }
        #expect(entry != nil)
        #expect(entry?.title == "通用")
        #expect(entry?.systemImage == "gearshape")
        #expect(entry?.order == 5)
    }

    @Test("数据库插件向设置视图注入「数据库」入口")
    func dbPluginInjectsDatabaseEntry() throws {
        let (kernel, settingView) = try HostEnv.makeKernelWithSettingView()

        try kernel.start(plugins: HostEnv.placeholders() + [HostDBPlugin()])

        let entry = settingView.entries.first { $0.id == "database" }
        #expect(entry != nil)
        #expect(entry?.title == "数据库")
        #expect(entry?.order == 40)
    }

    @Test("数据库插件停机时撤回「数据库」入口")
    func dbPluginRemovesDatabaseEntryOnShutdown() throws {
        let (kernel, settingView) = try HostEnv.makeKernelWithSettingView()
        try kernel.start(plugins: HostEnv.placeholders() + [HostDBPlugin()])
        #expect(settingView.entries.contains { $0.id == "database" })

        try kernel.stop()

        #expect(settingView.entries.contains { $0.id == "database" } == false)
    }
}

/// 设置入口的视图工厂可被构造。
///
/// `ShellCenter` 的设置入口用 `@ViewBuilder` 闭包保存详情视图，
/// 闭包体是惰性求值的（只有真正构造视图时才执行），
/// 这里逐个调用 `makeView()` 把这些闭包体跑一遍。
@MainActor
@Suite("Host 设置入口视图工厂")
struct HostEntryViewFactoryTests {

    @Test("每个设置入口的视图工厂都能产出视图")
    func everyEntryBuildsItsView() throws {
        let kernel = try HostEnv.makeShellOnlyKernel()
        let shell = try #require(kernel.resolveProvider(SettingsProviding.self) as? ShellCenter)

        try kernel.start(plugins: HostEnv.placeholders() + HostActionPluginAssembly.makePlugins())

        let entries = shell.entries
        #expect(!entries.isEmpty)
        for entry in entries {
            let view = entry.makeView()
            #expect(view != nil)
        }
    }

    @Test("数据库设置入口的详情视图工厂能产出视图")
    func databaseEntryBuildsDetailView() throws {
        let (kernel, settingView) = try HostEnv.makeKernelWithSettingView()
        try kernel.start(plugins: HostEnv.placeholders() + [HostDBPlugin()])

        let entry = try #require(settingView.entries.first { $0.id == "database" })
        let detail = entry.makeDetailView()

        #expect(detail != nil)
    }

    @Test("通用设置入口的详情视图工厂能产出视图")
    func generalEntryBuildsDetailView() throws {
        let (kernel, settingView) = try HostEnv.makeKernelWithSettingView()
        try kernel.start(plugins: HostEnv.placeholders() + [HostSettingsPlugin()])

        let entry = try #require(settingView.entries.first { $0.id == "general" })
        let detail = entry.makeDetailView()

        #expect(detail != nil)
    }
}
