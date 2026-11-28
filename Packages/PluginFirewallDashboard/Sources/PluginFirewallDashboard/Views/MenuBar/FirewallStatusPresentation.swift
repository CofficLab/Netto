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

    init(state: FirewallState, isFilterResponding: Bool = true) {
        // 配置启用但扩展没有心跳：系统里过滤器是「开启」的，实际却不在拦截。
        if state == .running, isFilterResponding == false {
            symbol = "exclamationmark.shield.fill"
            color = .orange
            title = String(localized: "Firewall Not Active")
            detail = String(localized: "The filter is not responding. Traffic may not be blocked.")
            return
        }

        switch state {
        case .running:
            symbol = "shield.fill"
            color = .green
            title = String(localized: "Firewall Running")
            detail = String(localized: "Blocking unauthorized network access")
        case .stopped:
            symbol = "shield.slash"
            color = .secondary
            title = String(localized: "Firewall Stopped")
            detail = String(localized: "Start it to block unauthorized network access")
        case .unknown:
            symbol = "shield"
            color = .secondary
            title = String(localized: "Firewall Status Unknown")
            detail = String(localized: "Click \"Start\" to check again")
        case .disabled:
            symbol = "shield.slash"
            color = .secondary
            title = String(localized: "Firewall Disabled")
            detail = String(localized: "The filter is disabled in System Settings")
        case .installing:
            symbol = "shield.lefthalf.filled"
            color = .orange
            title = String(localized: "Installing System Extension")
            detail = String(localized: "Please wait…")
        case .waitingForApproval, .systemExtensionApprovalNeeded:
            symbol = "shield.lefthalf.filled"
            color = .orange
            title = String(localized: "Waiting for System Extension Approval")
            detail = String(localized: "Enable the extension in System Settings")
        case .filterApprovalNeeded:
            symbol = "shield.lefthalf.filled"
            color = .orange
            title = String(localized: "Filter Needs Approval")
            detail = String(localized: "Allow the filter in System Settings")
        case .extensionNotActivated, .systemExtensionNotInstalled, .systemExtensionNeedsUpdate:
            symbol = "shield.lefthalf.filled"
            color = .orange
            title = String(localized: "System Extension Not Ready")
            detail = String(localized: "Complete the system extension installation using the guide below")
        case .filterNotInstalled:
            symbol = "shield.lefthalf.filled"
            color = .orange
            title = String(localized: "Filter Not Installed")
            detail = String(localized: "Install the filter using the guide below")
        case .notInApplicationsFolder:
            symbol = "exclamationmark.shield.fill"
            color = .orange
            title = String(localized: "Move to Applications Folder")
            detail = String(localized: "Move the app to /Applications and try again")
        case .permissionDenied:
            symbol = "exclamationmark.shield.fill"
            color = .red
            title = String(localized: "Permission Denied")
            detail = String(localized: "Grant permission in System Settings")
        case let .failed(failure):
            symbol = "exclamationmark.shield.fill"
            color = .red
            title = String(localized: "Firewall Error")
            detail = failure.message
        }
    }
}
