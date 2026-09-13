import SwiftUI
import ProviderViewEnvironment
import MagicCore
import MagicBackground
import ProviderFirewall

/**
 * 引导视图
 * 
 * 根据防火墙状态和升级状态显示相应的引导界面。
 * 包括升级引导、安装引导、状态引导等多种场景。
 */
struct GuideView: View {
    /// UI状态提供者
    @EnvironmentObject private var app: UIProvider
    
    /// 防火墙契约（nil = 未装配，按未运行处理）
    @Environment(\.firewallProvider) private var firewall: FirewallProviding?

    /// 构建引导视图
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
            MagicBackground.forest.opacity(0.3)

            VStack(spacing: 0) {
                // 优先显示升级引导界面：如果用户需要升级，优先显示升级引导
                if app.shouldShowUpgradeGuide {
                    UpgradeGuideView()
                } else {
                    // 根据防火墙状态显示对应的引导视图
                    // 状态语义与旧 FilterStatus 一一对应；nil 视为未运行
                    switch firewall?.snapshot.state {
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
                        // 等待用户批准安装扩展
                        Text("Click \"Allow\" to install extension")
                            .font(.title)
                        Image("Ask")
                    case .extensionNotActivated:
                        ExtensionNotReady()
                    case .notInApplicationsFolder:
                        NotInApplicationsFolderView()
                    case let .failed(failure):
                        ErrorView(error: FirewallFailureError(failure: failure))
                    }
                }
            }
            .background(.background)
            .cornerRadius(16)
            .padding(20)
            .shadow(color: Color.blue.opacity(0.2), radius: 10, x: 0, y: 2)
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
    GuideView()
        .dashboardPreviewRoot()
        .frame(width: 600, height: 800)
}
