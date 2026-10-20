import Foundation
import KernelCore
import ProviderShell
import Testing
@testable import PluginHostActions

// MARK: - 测试脚手架

/// 依赖占位插件：用生产 id 满足 Kernel 的依赖解析，不注册任何契约。
@MainActor
private final class DependencyPlaceholder: SuperPlugin {
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

/// 生产依赖链的占位插件（Kernel 会校验 dependencies 声明的插件必须存在）。
@MainActor
private enum DependencyStubs {
    static let ids = ["persistence", "appsettings", "eventstore", "firewall"]

    static func make() -> [any SuperPlugin] {
        ids.map(DependencyPlaceholder.init(id:))
    }

    /// 预置 ShellCenter 并注册依赖占位，返回已就绪的 Kernel。
    static func makeKernel() throws -> KernelCoreContainer {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider(SettingsProviding.self, ShellCenter())
        return kernel
    }
}

// MARK: - 测试

/// Host 操作插件目录的装配与生命周期测试。
///
/// 不触碰视图渲染与真实系统设置跳转，只验证「插件注册了什么、顺序是否稳定、
/// 停止后是否干净撤回」——这些是回归时最容易坏、也最难靠肉眼发现的部分。
@MainActor
@Suite("HostActionPluginAssembly")
struct HostActionAssemblyTests {

    // MARK: - 目录不变量

    @Test("生产目录插件 id 唯一")
    func pluginIdsUnique() {
        let ids = HostActionPluginAssembly.makePlugins().map(\.id)
        #expect(!ids.isEmpty)
        #expect(Set(ids).count == ids.count, "插件 id 重复会被 KernelCore 拒绝：\(ids)")
    }

    @Test("插件 id 均非空且 order 唯一")
    func ordersUniqueAndIdsNonEmpty() {
        let plugins = HostActionPluginAssembly.makePlugins()
        for plugin in plugins {
            #expect(!plugin.id.isEmpty)
        }
        let orders = plugins.map(\.order)
        #expect(Set(orders).count == orders.count, "order 重复会导致启动顺序不确定：\(orders)")
    }

    @Test("数据库与清空日志插件仅在 DEBUG 出现")
    func debugOnlyPlugins() {
        let ids = HostActionPluginAssembly.makePlugins().map(\.id)
        #if DEBUG
        #expect(ids.contains("db"))
        #expect(ids.contains("clearlogs"))
        #else
        #expect(!ids.contains("db"))
        #expect(!ids.contains("clearlogs"))
        #endif
    }

    @Test("顺序敏感插件声明了正确的依赖")
    func dependenciesDeclared() {
        let byID = Dictionary(
            uniqueKeysWithValues: HostActionPluginAssembly.makePlugins().map { ($0.id, $0) }
        )

        // 依赖持久化层的插件必须声明 persistence。
        #expect(byID["datafolder"]?.dependencies.contains("persistence") == true)
        // 依赖事件存储的插件必须声明 eventstore。
        #expect(byID["db"]?.dependencies.contains("eventstore") == true)
        #expect(byID["clearlogs"]?.dependencies.contains("eventstore") == true)
        // 依赖防火墙的插件必须声明 firewall。
        #expect(byID["installextension"]?.dependencies.contains("firewall") == true)
        // 数据库插件同时依赖设置规则。
        #expect(byID["db"]?.dependencies.contains("appsettings") == true)
    }

    @Test("声明的依赖 id 均在生产依赖链占位集合中")
    func dependenciesAreKnown() {
        // 依赖 id 拼错时 Kernel 会在启动期报 pluginDependencyMissing，
        // 这里提前把「拼错」变成测试失败，定位更快。
        for plugin in HostActionPluginAssembly.makePlugins() {
            for dependency in plugin.dependencies {
                #expect(
                    DependencyStubs.ids.contains(dependency),
                    "\(plugin.id) 声明了未知依赖 \(dependency)"
                )
            }
        }
    }

    // MARK: - 生命周期

    @Test("启动后设置入口按 order 注入")
    func lifecycleRegistersEntries() async throws {
        let kernel = try DependencyStubs.makeKernel()
        let shell = try #require(kernel.resolveProvider(SettingsProviding.self) as? ShellCenter)

        try await kernel.startAsync(
            plugins: DependencyStubs.make() + HostActionPluginAssembly.makePlugins()
        )
        defer { Task { try? await kernel.stopAsync() } }

        let ids = shell.entries.map(\.id)
        for expected in ["appsettings", "guide", "datafolder", "installextension", "about", "quit"] {
            #expect(ids.contains(expected), "缺少设置入口 \(expected)：\(ids)")
        }

        // 设置入口应按 order 升序排列（用户可见顺序）。
        let orders = shell.entries.map(\.order)
        #expect(orders == orders.sorted(), "设置入口应按 order 升序：\(orders)")
    }

    @Test("重复启动不产生重复设置入口")
    func noDuplicateEntriesOnRestart() async throws {
        let kernel = try DependencyStubs.makeKernel()
        let shell = try #require(kernel.resolveProvider(SettingsProviding.self) as? ShellCenter)
        let plugins = DependencyStubs.make() + HostActionPluginAssembly.makePlugins()

        try await kernel.startAsync(plugins: plugins)
        let firstIDs = shell.entries.map(\.id)
        #expect(!firstIDs.isEmpty)
        try await kernel.stopAsync()

        // 注意：本目录插件直接调用 `ShellCenter.registerEntry`，未走 Kernel 的
        // `trackContribution`，因此停止时 Kernel 不会自动撤回这些入口。
        // ShellCenter 内部按 entry.id 存字典，故重启后条目数保持一致而非累加；
        // 这里锁定该行为，避免将来有人误以为已自动撤回。
        try await kernel.startAsync(plugins: plugins)
        #expect(shell.entries.map(\.id) == firstIDs, "重启后设置入口应保持一致而非累加")
        try await kernel.stopAsync()
    }

    @Test("缺少 Shell 契约时启动失败且状态标记为 failed")
    func failsWithoutShellContract() {
        // 不注册 SettingsProviding：需要 Shell 契约的插件必须抛出而非静默跳过，
        // 否则设置面板会整片消失而无人察觉。
        let kernel = KernelCoreContainer()
        #expect(throws: (any Error).self) {
            try kernel.start(
                plugins: DependencyStubs.make() + HostActionPluginAssembly.makePlugins()
            )
        }
        #expect(kernel.lifecycleState == .failed)
    }

    @Test("仅数据库插件在缺少设置视图契约时优雅降级")
    func dbPluginDegradesWithoutSettingView() throws {
        // HostDBPlugin 对 SettingViewProviding 缺失是优雅降级（不阻塞启动），
        // 与其他插件的「缺契约即失败」形成对比，单独锁定该差异。
        let kernel = try DependencyStubs.makeKernel()
        try kernel.start(plugins: DependencyStubs.make() + [HostDBPlugin()])
        #expect(kernel.lifecycleState == .running)
        try kernel.stop()
    }

    // MARK: - 预览贡献

    @Test("预览贡献注册与生产相同的设置入口")
    func previewContributionsMirrorProduction() throws {
        let previewShell = ShellCenter()
        HostActionPluginAssembly.registerPreviewContributions(into: previewShell)
        let previewIDs = previewShell.entries.map(\.id)

        // 生产路径经 Kernel 启动，撤回前应注册同一批入口。
        let kernel = try DependencyStubs.makeKernel()
        let shell = try #require(kernel.resolveProvider(SettingsProviding.self) as? ShellCenter)
        try kernel.start(plugins: DependencyStubs.make() + HostActionPluginAssembly.makePlugins())

        #expect(!previewIDs.isEmpty)
        #expect(previewIDs == shell.entries.map(\.id))
        try kernel.stop()
    }
}

/// `Date.fullDateTime` 格式测试（数据库详情视图的时间展示依赖该格式）。
@Suite("Date 格式化")
struct HostActionDateTests {
    @Test("输出定长 19 字符的 yyyy-MM-dd HH:mm:ss")
    func fullDateTimeFormat() {
        let rendered = Date(timeIntervalSince1970: 1_700_000_000).fullDateTime
        let chars = Array(rendered)
        #expect(chars.count == 19)
        #expect(chars[4] == "-" && chars[7] == "-")
        #expect(chars[10] == " ")
        #expect(chars[13] == ":" && chars[16] == ":")
    }
}
