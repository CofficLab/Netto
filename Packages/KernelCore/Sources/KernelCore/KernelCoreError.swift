import Foundation

/// KernelCore 全部可诊断错误。
///
/// 保持 `Sendable` 以便跨 actor 边界传递；`CustomStringConvertible`
/// 保证启动失败时能给出可复制、可定位的描述。
public enum KernelCoreError: Error, Sendable, Equatable, CustomStringConvertible {
    /// 插件 ID 重复注册。
    case pluginAlreadyRegistered(id: String)

    /// 按 ID 解析插件失败。
    case pluginNotFound(id: String)

    /// 插件声明了缺失的依赖（依赖既不在本批插件中，也未被已注册插件提供）。
    case pluginDependencyMissing(pluginID: String, dependencyID: String)

    /// 插件依赖成环，给出环内 ID（已排序）。
    case pluginDependencyCycle(ids: [String])

    /// 同协议类型 Provider 重复注册。
    case providerAlreadyRegistered(type: String)

    /// 请求必需的 Provider 但未注册。
    case providerNotFound(type: String)

    /// 非法生命周期操作（如 stopped 状态下 stop、重复 start、卸载被依赖插件）。
    case invalidLifecycleOperation(operation: String, state: String)

    /// 插件实现了 AsyncSuperPlugin，却通过同步 start(plugins:) 启动。
    case asyncLifecycleRequired(pluginID: String)

    /// 异步生命周期阶段超时。
    case asyncPhaseTimeout(pluginID: String, phase: String)

    /// 异步生命周期阶段被取消（宿主 Task 取消）。
    case asyncPhaseCancelled(pluginID: String, phase: String)

    public var description: String {
        switch self {
        case .pluginAlreadyRegistered(let id):
            return "插件已注册: \(id)"
        case .pluginNotFound(let id):
            return "插件未找到: \(id)"
        case .pluginDependencyMissing(let pluginID, let dependencyID):
            return "插件 '\(pluginID)' 声明了缺失依赖 '\(dependencyID)'"
        case .pluginDependencyCycle(let ids):
            return "插件依赖成环: \(ids.joined(separator: " -> "))"
        case .providerAlreadyRegistered(let type):
            return "Provider 重复注册: \(type)"
        case .providerNotFound(let type):
            return "Provider 未注册: \(type)"
        case .invalidLifecycleOperation(let operation, let state):
            return "非法生命周期操作 '\(operation)'（当前状态: \(state)）"
        case .asyncLifecycleRequired(let pluginID):
            return "插件 '\(pluginID)' 需要异步生命周期，请使用 startAsync(plugins:)"
        case .asyncPhaseTimeout(let pluginID, let phase):
            return "插件 '\(pluginID)' 异步阶段 '\(phase)' 超时"
        case .asyncPhaseCancelled(let pluginID, let phase):
            return "插件 '\(pluginID)' 异步阶段 '\(phase)' 被取消"
        }
    }
}
