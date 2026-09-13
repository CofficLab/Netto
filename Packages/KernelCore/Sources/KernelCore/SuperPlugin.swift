import Foundation

/// 超级插件协议 —— 插件向内核注入能力 / 调用内核能力的最小契约。
///
/// 生命周期语义：
/// - `onRegister(kernel:)`：插件注册到 Kernel 后调用，只登记不依赖运行状态的
///   目录型贡献（元数据、注册表条目），无论插件是否启用都会执行。
/// - `onBoot(kernel:)`：插件启动阶段，注册自己的 Provider 与可撤销资源。
/// - `onReady(kernel:)`：全部插件完成 Boot 后调用，可安全解析依赖插件的 Provider。
/// - `onShutdown(kernel:)`：插件卸载或内核停止时逆序执行，撤回外部资源。
/// - `onUnregister(kernel:)`：插件从 Kernel 注销前调用，撤回 `onRegister` 的目录贡献。
/// - `onEnable(kernel:)` / `onDisable(kernel:)`：运行时启用/禁用；Kernel 在
///   `onDisable` 成功后自动撤回该插件登记的贡献。
///
/// 线程/actor：所有生命周期方法都在 `@MainActor` 上执行（Kernel 为 MainActor 容器）。
@MainActor
public protocol SuperPlugin: AnyObject {
    /// 插件唯一稳定 ID。
    var id: String { get }

    /// 插件加载顺序，数值越小越先 Boot（默认 200）。
    var order: Int { get }

    /// 必须先于当前插件启动的插件 ID 列表（默认无依赖）。
    var dependencies: [String] { get }

    /// 用于诊断和权限展示的稳定元数据。
    var metadata: PluginMetadata { get }

    /// 注册阶段：登记目录型贡献，不得启动外部资源。
    func onRegister(kernel: KernelCoreContainer) throws

    /// 启动阶段：向内核注入能力（注册 Provider、登记贡献）。
    func onBoot(kernel: KernelCoreContainer) throws

    /// 全部插件 Boot 完成后调用，连接跨插件能力。
    func onReady(kernel: KernelCoreContainer) throws

    /// 停止阶段：停止监听、Task、IPC、定时器并释放外部资源。
    func onShutdown(kernel: KernelCoreContainer) throws

    /// 注销阶段：撤回 `onRegister` 登记的目录贡献。
    func onUnregister(kernel: KernelCoreContainer) throws

    /// 运行时启用：恢复被禁用时停止的资源。
    func onEnable(kernel: KernelCoreContainer) async throws

    /// 运行时禁用：停止本插件运行资源；Kernel 随后撤回其贡献。
    func onDisable(kernel: KernelCoreContainer) async throws
}

public extension SuperPlugin {
    var order: Int { 200 }

    var dependencies: [String] { [] }

    func onRegister(kernel: KernelCoreContainer) throws {}

    func onBoot(kernel: KernelCoreContainer) throws {}

    func onReady(kernel: KernelCoreContainer) throws {}

    func onShutdown(kernel: KernelCoreContainer) throws {}

    func onUnregister(kernel: KernelCoreContainer) throws {}

    func onEnable(kernel: KernelCoreContainer) async throws {}

    func onDisable(kernel: KernelCoreContainer) async throws {}
}

/// 需要异步 Boot / Ready / Shutdown 的插件使用该协议。
///
/// 同步 `SuperPlugin` 保留为轻量插件和迁移期兼容入口；宿主必须通过
/// `startAsync(plugins:)` 启动实现本协议的插件，避免异步初始化被静默跳过。
@MainActor
public protocol AsyncSuperPlugin: SuperPlugin {
    func onBootAsync(kernel: KernelCoreContainer) async throws
    func onReadyAsync(kernel: KernelCoreContainer) async throws
    func onShutdownAsync(kernel: KernelCoreContainer) async throws
}

public extension AsyncSuperPlugin {
    func onBootAsync(kernel: KernelCoreContainer) async throws {
        try onBoot(kernel: kernel)
    }

    func onReadyAsync(kernel: KernelCoreContainer) async throws {
        try onReady(kernel: kernel)
    }

    func onShutdownAsync(kernel: KernelCoreContainer) async throws {
        try onShutdown(kernel: kernel)
    }
}
