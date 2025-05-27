import Foundation

enum FilterStatus {
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
            "请在弹出的对话框中点击“允许”"
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

    func isStopped() -> Bool {
        switch self {
        case .stopped:
            true
        default:
            false
        }
    }
}

