import Foundation

enum FilterStatus {
    case stopped
    case indeterminate
    case running
    case notInstalled
    case rejected
    case needApproval
    
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
        case .rejected:
            "被拒绝"
        case .needApproval:
            "待授权"
        }
    }
}
