import Foundation

enum FilterStatus: Equatable {
    case stopped
    case indeterminate
    case running
    case notInstalled
    case needSystemExtensionApproval
    case filterNeedApproval
    case waitingForApproval
    case disabled
    case extensionNotActivated
    case notInApplicationsFolder
    case systemExtensionNotInstalled
    case systemExtensionNeedUpdate
    case filterNotInstalled
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
        case .needSystemExtensionApproval:
            "需要用户同意安装系统扩展"
        case .filterNeedApproval:
            "过滤器需要用户授权"
        case .waitingForApproval:
            "请在弹出的对话框中点击\"允许\""
        case .disabled:
            "disabled"
        case .extensionNotActivated:
            "extension未激活"
        case .notInApplicationsFolder:
            "APP未安装在Applications目录"
        case .systemExtensionNotInstalled:
            "系统扩展未安装"
        case .systemExtensionNeedUpdate:
            "需要更新系统扩展"
        case .filterNotInstalled:
            "过滤器未安装"
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

    func isExtensionNotActivated() -> Bool {
        switch self {
        case.extensionNotActivated:
            true
        default:
            false
        }
    }

    func isNotInApplicationsFolder() -> Bool {
        switch self {
        case.notInApplicationsFolder:
            true
        default:
            false
        }
    }

    func isSystemExtensionNotInstalled() -> Bool {
        switch self {
        case.systemExtensionNotInstalled:
            true
        default:
            false
        }
    }

    func isSystemExtensionNeedUpdate() -> Bool {
        switch self {
        case.systemExtensionNeedUpdate:
            true
        default:
            false
        }
    }

    func isFilterNotInstalled() -> Bool {
        switch self {
        case.filterNotInstalled:
            true
        default:
            false
        }
    }

    func isNeedSystemExtensionApproval() -> Bool {
        switch self {
        case.needSystemExtensionApproval:
            true
        default:
            false
        }
    }

    func isFilterNeedApproval() -> Bool {
        switch self {
        case.filterNeedApproval:
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
        case .error, .notInstalled,.waitingForApproval, .needSystemExtensionApproval, .filterNeedApproval, .extensionNotActivated, .notInApplicationsFolder, .systemExtensionNotInstalled, .systemExtensionNeedUpdate, .filterNotInstalled:
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
             (.needSystemExtensionApproval, .needSystemExtensionApproval),
             (.filterNeedApproval, .filterNeedApproval),
             (.waitingForApproval, .waitingForApproval),
             (.disabled, .disabled),
             (.extensionNotActivated, .extensionNotActivated),
             (.notInApplicationsFolder, .notInApplicationsFolder),
             (.systemExtensionNotInstalled, .systemExtensionNotInstalled),
             (.systemExtensionNeedUpdate, .systemExtensionNeedUpdate),
             (.filterNotInstalled, .filterNotInstalled):
            return true
        case (.error(let error1), .error(let error2)):
            // 由于 Error 不符合 Equatable，我们比较错误的描述
            return error1.localizedDescription == error2.localizedDescription
        default:
            return false
        }
    }
}

