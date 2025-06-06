import Foundation

enum FilterStatus: Equatable {
    case stopped
    case indeterminate
    case running
    case notInstalled
    case needApproval
    case waitingForApproval
    case disabled
    case extensionNotReady
    case error(Error)
    
    var description: String {
        switch self {
        case .stopped:
            "已停止"
        case .indeterminate:
            "未知"
        case .running:
            "运行中"
        case .notInstalled:
            "未安装"
        case .needApproval:
            "待授权"
        case .waitingForApproval:
            "请在弹出的对话框中点击\"允许\""
        case .disabled:
            "disabled"
        case .extensionNotReady:
            "extensionNotReady"
        case .error(let error):
            "错误: \(error.localizedDescription)"
        }
}

    func isRunning() -> Bool {
        switch self {
        case .running:
            true
        default:
            false
        }
    }
    
    func isNotRunning() -> Bool {
        !isRunning()
    }

    func isStopped() -> Bool {
        switch self {
        case .stopped:
            true
        default:
            false
        }
    }

    func isNotInstalled() -> Bool {
        switch self {
        case.notInstalled:
            true
        default:
            false
        }
    }

    func isDisabled() -> Bool {
        switch self {
        case.disabled:
            true
        default:
            false
        }
    }

    func isExtensionNotReady() -> Bool {
        switch self {
        case.extensionNotReady:
            true
        default:
            false
        }
    }   

    func isNeedApproval() -> Bool {
        switch self {
        case.needApproval:
            true
        default:
            false
        }
    }

    func isWaitingForApproval() -> Bool {
        switch self {
        case.waitingForApproval:
            true
        default:
            false
        }
    }

    func isError() -> Bool {
        switch self {
        case.error:
            true
        default:
            false
        }
    }

    func canStart() -> Bool {
        switch self {
        case.stopped, .indeterminate,  .disabled:
            true
        case .error, .notInstalled,.waitingForApproval, .needApproval, .extensionNotReady:
            false
        default:
            false
        }
    }
    
    // 实现 Equatable 协议的 == 运算符
    static func == (lhs: FilterStatus, rhs: FilterStatus) -> Bool {
        switch (lhs, rhs) {
        case (.stopped, .stopped),
             (.indeterminate, .indeterminate),
             (.running, .running),
             (.notInstalled, .notInstalled),
             (.needApproval, .needApproval),
             (.waitingForApproval, .waitingForApproval),
             (.disabled, .disabled),
             (.extensionNotReady, .extensionNotReady):
            return true
        case (.error(let error1), .error(let error2)):
            // 由于 Error 不符合 Equatable，我们比较错误的描述
            return error1.localizedDescription == error2.localizedDescription
        default:
            return false
        }
    }
}

