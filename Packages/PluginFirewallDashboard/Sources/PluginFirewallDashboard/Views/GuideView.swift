import LumiUI
import ProviderViewEnvironment
import ProviderFirewall
import SwiftUI

/// 引导视图 —— 防火墙未就绪时覆盖在应用列表上的状态面板。
///
/// 按防火墙状态与升级状态选择对应的 `DashboardGuidePanel` 内容；遮罩使用
/// 系统材质，面板本身由 LumiUI 主题表面渲染。
struct GuideView: View {
    /// 由宿主订阅 `FirewallProviding.observe()` 后传入的最新状态。
    let state: FirewallState?

    /// 运行中过滤器是否仍有扩展心跳；false 时提示未生效并提供修复入口。
    var isFilterResponding = true

    /// App 与扩展的 IPC 是否已建立；断开时优先提示连接中断。
    var isIPCConnected = true

    /// 外层展示形式使用材质遮罩；菜单栏弹窗内不需要遮罩，只渲染面板本身。
    var showsBackdrop = true

    @EnvironmentObject private var app: UIProvider

    var body: some View {
        ZStack {
            if showsBackdrop {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // 升级引导优先于状态引导。
                if app.shouldShowUpgradeGuide {
                    UpgradeGuideView()
                } else {
                    switch state {
                    case .stopped, nil:
                        StopView()
                    case .disabled:
                        SystemSettingsGuideView(
                            title: "Firewall Disabled",
                            message: "The filter is disabled in System Settings. Enable it to block unauthorized network access.",
                            iconName: "shield.slash"
                        )
                    case .unknown:
                        UnknownView()
                    case .installing:
                        InstallingView()
                    case .running:
                        // 运行中一般不展示引导。IPC 断开时扩展会放行流量，
                        // 与「过滤器未生效」是两种故障，分开提示；其余情况
                        // 才用心跳判定是否生效。
                        if !isIPCConnected {
                            ExtensionConnectionLostView()
                        } else if isFilterResponding {
                            EmptyView()
                        } else {
                            FilterUnresponsiveView()
                        }
                    case .systemExtensionNotInstalled:
                        SystemExtensionNotInstalledView()
                    case .systemExtensionNeedsUpdate:
                        SystemExtensionNeedUpdateView()
                    case .filterNotInstalled:
                        FilterNotInstalledView()
                    case .systemExtensionApprovalNeeded, .filterApprovalNeeded, .waitingForApproval:
                        ApprovalView()
                    case .permissionDenied:
                        SystemSettingsGuideView(
                            title: "Permission Denied",
                            message: "Grant the required permissions in System Settings and try again.",
                            iconName: "exclamationmark.shield.fill",
                            iconColor: .red
                        )
                    case .extensionNotActivated:
                        ExtensionNotReady()
                    case .notInApplicationsFolder:
                        NotInApplicationsFolderView()
                    case let .failed(failure):
                        ErrorView(error: FirewallFailureError(failure: failure))
                    }
                }
            }
            .padding(AppUI.Spacing.lg)
            .frame(maxWidth: .infinity)
            // 作为无障碍容器暴露引导标识，避免标识下发给子元素后覆盖
            // 按钮自身的 accessibilityIdentifier。
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("netpause.firewall.guide")
        }
    }
}

// MARK: - Preview
#Preview("App") {
    ContentView()
        .dashboardPreviewRoot()
        .frame(width: 600, height: 600)
}

#Preview("GuideView") {
    GuideView(state: .stopped)
        .dashboardPreviewRoot()
        .frame(width: 600, height: 800)
}
