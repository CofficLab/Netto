import SwiftUI
import MagicCore
import MagicBackground

/**
 * 引导视图
 * 
 * 根据防火墙状态和升级状态显示相应的引导界面。
 * 包括升级引导、安装引导、状态引导等多种场景。
 */
struct GuideView: View {
    /// UI状态提供者
    @EnvironmentObject private var app: UIProvider
    
    /// 防火墙服务
    @EnvironmentObject private var firewall: FirewallService

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
                    switch firewall.status {
                    case .disabled, .stopped:
                        StopView()
                    case .indeterminate:
                        UnknownView()
                    case .running:
                        RunningView()
                    case .notInstalled:
                        InstallView()
                    case .needSystemExtensionApproval:
                        ApprovalView()
                    case .filterNeedApproval:
                        ApprovalView()
                    case .extensionNotActivated:
                        ExtensionNotReady()
                    case .notInApplicationsFolder:
                        NotInApplicationsFolderView()
                    case .waitingForApproval:
                        // 等待用户批准安装扩展
                        Text("Click \"Allow\" to install extension")
                            .font(.title)
                        Image("Ask")
                    case let .error(error):
                        ErrorView(error: error)
                    case .systemExtensionNotInstalled:
                        SystemExtensionNotInstalledView()
                    case .systemExtensionNeedUpdate:
                        SystemExtensionNeedUpdateView()
                    case .filterNotInstalled:
                        FilterNotInstalledView()
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
        .inRootView()
        .frame(width: 600, height: 600)
}

#Preview("GuideView") {
    GuideView()
        .inRootView()
        .frame(width: 600, height: 800)
}
