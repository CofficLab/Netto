import Foundation

/// 插件启用策略。
///
/// 决定插件在 `start(plugins:)` / `startAsync(plugins:)` 时的默认启用状态：
/// - `.required` / `.alwaysOn`：强制启用，不受用户持久化覆盖影响。
/// - `.disabled`：彻底排除，不注册、不启动、不展示。
/// - `.enabledByDefault` / `.disabledByDefault`：可配置插件，优先读取
///   `PluginEnableStateStoring` 中的用户覆盖，未覆盖时使用默认值。
public enum PluginEnablePolicy: Sendable, Equatable, Hashable {
    case required
    case alwaysOn
    case disabled
    case enabledByDefault
    case disabledByDefault

    /// 该策略在没有用户覆盖时的默认启用值。
    var enabledByDefault: Bool {
        switch self {
        case .required, .alwaysOn, .enabledByDefault:
            return true
        case .disabled, .disabledByDefault:
            return false
        }
    }
}

/// 插件稳定元数据。
///
/// 用于插件管理、诊断和权限展示；不携带任何运行时资源。
public struct PluginMetadata: Sendable, Equatable, Hashable {
    /// 面向用户/日志的插件显示名。
    public let name: String

    /// 插件版本。
    public let version: String

    /// 插件启用策略。
    public let policy: PluginEnablePolicy

    /// 插件用途描述（可选）。
    public let summary: String?

    /// 创建插件元数据。
    public init(
        name: String,
        version: String,
        policy: PluginEnablePolicy = .enabledByDefault,
        summary: String? = nil
    ) {
        self.name = name
        self.version = version
        self.policy = policy
        self.summary = summary
    }
}
