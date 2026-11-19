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

    /// 主窗口形态使用材质遮罩；菜单栏弹窗内不需要遮罩，只渲染面板本身。
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
                    case .disabled, .stopped, nil:
                        StopView()
                    case .unknown, .installing:
                        UnknownView()
                    case .running:
                        RunningView()
                    case .systemExtensionNotInstalled:
                        SystemExtensionNotInstalledView()
                    case .systemExtensionNeedsUpdate:
                        SystemExtensionNeedUpdateView()
                    case .filterNotInstalled:
                        FilterNotInstalledView()
                    case .systemExtensionApprovalNeeded, .filterApprovalNeeded, .permissionDenied:
                        ApprovalView()
                    case .waitingForApproval:
                        DashboardGuidePanel(
                            iconName: "hand.raised.fill",
                            title: "等待系统批准",
                            iconColor: .orange
                        ) {
                            Text("请在系统设置中启用网络扩展以完成安装。")
                                .font(.appBody)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
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
            .accessibilityIdentifier("netto.firewall.guide")
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
