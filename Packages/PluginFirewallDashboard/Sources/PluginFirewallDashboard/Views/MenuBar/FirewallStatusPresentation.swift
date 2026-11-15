import ProviderFirewall
import SwiftUI

/// 防火墙状态的菜单栏展示映射（图标 / 颜色 / 标题 / 说明）。
///
/// 状态栏图标与弹出面板共用同一份映射，避免两处文案与图标漂移。
struct FirewallStatusPresentation {
    let symbol: String
    let color: Color
    let title: String
    let detail: String

    init(state: FirewallState) {
        switch state {
        case .running:
            symbol = "shield.fill"
            color = .green
            title = "防火墙运行中"
            detail = "正在拦截未授权联网"
        case .stopped:
            symbol = "shield.slash"
            color = .secondary
            title = "防火墙已停止"
            detail = "开启后开始拦截未授权联网"
        case .unknown:
            symbol = "shield"
            color = .secondary
            title = "防火墙状态未知"
            detail = "点击「开启」重新检测"
        case .disabled:
            symbol = "shield.slash"
            color = .secondary
            title = "防火墙已禁用"
            detail = "过滤器在系统设置中被禁用"
        case .installing:
            symbol = "shield.lefthalf.filled"
            color = .orange
            title = "正在安装系统扩展"
            detail = "请稍候…"
        case .waitingForApproval, .systemExtensionApprovalNeeded:
            symbol = "shield.lefthalf.filled"
            color = .orange
            title = "等待批准系统扩展"
            detail = "请在系统弹窗中允许扩展"
        case .filterApprovalNeeded:
            symbol = "shield.lefthalf.filled"
            color = .orange
            title = "过滤器需要授权"
            detail = "请在系统设置中允许过滤器"
        case .extensionNotActivated, .systemExtensionNotInstalled, .systemExtensionNeedsUpdate:
            symbol = "shield.lefthalf.filled"
            color = .orange
            title = "系统扩展未就绪"
            detail = "请在主窗口完成系统扩展安装"
        case .filterNotInstalled:
            symbol = "shield.lefthalf.filled"
            color = .orange
            title = "过滤器未安装"
            detail = "请在主窗口安装过滤器"
        case .notInApplicationsFolder:
            symbol = "exclamationmark.shield.fill"
            color = .orange
            title = "需要移入应用程序文件夹"
            detail = "将 App 移入 /Applications 后重试"
        case .permissionDenied:
            symbol = "exclamationmark.shield.fill"
            color = .red
            title = "权限被拒绝"
            detail = "请在系统设置中授予权限"
        case let .failed(failure):
            symbol = "exclamationmark.shield.fill"
            color = .red
            title = "防火墙发生错误"
            detail = failure.message
        }
    }
}
