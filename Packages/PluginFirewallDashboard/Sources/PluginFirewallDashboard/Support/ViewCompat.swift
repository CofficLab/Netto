import Foundation
import ProviderFirewall
import ProviderFirewallEvents

// MARK: - FirewallState 视图兼容扩展

/// 视图层兼容扩展：镜像旧 `FilterStatus` 的命名，保持调用点语义不变。
/// 只读状态判断，无副作用。
public extension FirewallState {
    /// 是否运行中（旧 `FilterStatus.isRunning()`）。
    func isRunning() -> Bool {
        self == .running
    }

    /// 是否未运行（旧 `FilterStatus.isNotRunning()`）。
    func isNotRunning() -> Bool {
        self != .running
    }

    /// 是否已停止（旧 `FilterStatus.isStopped()`）。
    func isStopped() -> Bool {
        self == .stopped
    }
}

/// 把 `FirewallFailure` 适配为 `LocalizedError`，供旧 `ErrorView` 直接展示。
/// 不携带失败以外的状态；描述来自失败消息本身。
struct FirewallFailureError: LocalizedError {
    let failure: FirewallFailure

    var errorDescription: String? {
        failure.message
    }
}

// MARK: - FirewallEventSnapshot 视图兼容扩展

/// 视图层兼容扩展：保留旧 `FirewallEventDTO` 的展示字段。
extension FirewallEventSnapshot {
    /// 是否放行。
    public var isAllowed: Bool { status == .allowed }

    /// 完整时间展示（旧 `timeFormatted` 语义）。
    public var timeFormatted: String {
        time.fullDateTime
    }

    /// `address:port` 描述。
    public var description: String {
        "\(address):\(port)"
    }

    /// 状态中文描述（旧 `statusDescription` 语义）。
    public var statusDescription: String {
        switch status {
        case .allowed: "允许"
        case .rejected: "阻止"
        }
    }
}
