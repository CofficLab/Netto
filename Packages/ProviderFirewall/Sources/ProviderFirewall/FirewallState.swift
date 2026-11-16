import Foundation

/// 防火墙运行状态（中立值，不暴露 NEFilterManager / OSSystemExtension 类型）。
///
/// 与旧 `FilterStatus` 全量语义对应，**不得**把安装审批、系统扩展未激活、
/// 未安装在 Applications 等状态合并为 stopped。
public enum FirewallState: Sendable, Equatable, Hashable {
    /// 初始未知状态。
    case unknown
    /// 已停止。
    case stopped
    /// 运行中。
    case running
    /// 安装/激活流程进行中。
    case installing
    /// 等待用户在系统弹窗中批准系统扩展。
    case waitingForApproval
    /// 需要用户同意安装系统扩展（旧 `needSystemExtensionApproval`）。
    case systemExtensionApprovalNeeded
    /// 过滤器需要用户授权（旧 `filterNeedApproval`）。
    case filterApprovalNeeded
    /// 过滤器处于禁用（旧 `disabled`）。
    case disabled
    /// 系统扩展已安装但未激活（旧 `extensionNotActivated`）。
    case extensionNotActivated
    /// 系统扩展未安装。
    case systemExtensionNotInstalled
    /// 系统扩展需要更新。
    case systemExtensionNeedsUpdate
    /// 过滤器（系统设置中的 Filter）未安装。
    case filterNotInstalled
    /// App 未安装在 /Applications 目录。
    case notInApplicationsFolder
    /// 权限被拒绝。
    case permissionDenied
    /// 发生错误（保留完整失败信息）。
    case failed(FirewallFailure)

    /// 当前状态是否允许启动防火墙。
    public var canStart: Bool {
        switch self {
        case .stopped, .unknown, .installing, .disabled:
            return true
        default:
            return false
        }
    }

    /// 当前状态是否允许停止防火墙。
    public var canStop: Bool {
        switch self {
        case .running:
            return true
        default:
            return false
        }
    }
}

/// 防火墙失败信息（保留 domain/code/完整描述，展示层再映射本地化文案）。
public struct FirewallFailure: Sendable, Equatable, Hashable {
    /// 错误 domain。
    public let domain: String
    /// 错误 code。
    public let code: Int
    /// 完整本地化描述。
    public let message: String

    public init(domain: String, code: Int, message: String) {
        self.domain = domain
        self.code = code
        self.message = message
    }
}
