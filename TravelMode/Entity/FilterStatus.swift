import Foundation

enum FilterStatus {
    case stopped
    case indeterminate
    case running
    case notInstalled
    case needApproval
    case waitingForApproval
    
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
        }
    }
}
