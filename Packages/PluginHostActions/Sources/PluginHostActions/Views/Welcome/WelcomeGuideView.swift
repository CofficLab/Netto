import LumiUI
import SwiftUI

/// 欢迎引导视图（启动欢迎窗与「设置-通用-使用引导」共用）。
///
/// 无 Provider 环境依赖、不创建核心服务；`hasShownWelcome` 键与旧实现一致
/// （UserDefaults 键名不变）；`dismiss` 在 sheet/窗口场景下关闭自身。
///
/// 线程/actor：`View`；body 求值无副作用；按钮动作在主线程执行。
public struct WelcomeGuideView: View {
    @LumiTheme private var theme

    @State private var currentStep = 0
    @AppStorage("hasShownWelcome") private var hasShownWelcome = false
    @Environment(\.dismiss) private var dismiss

    public init() {}
    
    public var body: some View {
        VStack(spacing: AppUI.Spacing.lg) {
            // 头部
            VStack(spacing: AppUI.Spacing.md) {
                // 无 bundle 参数时从 main bundle 加载（App 运行时的 Assets.xcassets/Logo）
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                
                Text("Welcome to \(WelcomeGuideAppName.name)")
                    .font(.appLargeTitle)
                    .foregroundStyle(theme.textPrimary)
                
                Text("Network Filtering and Monitoring Tool")
                    .font(.appBody)
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(.top, AppUI.Spacing.xl)
            
            // 内容区域
            VStack(spacing: AppUI.Spacing.lg) {
                if currentStep == 0 {
                    stepView(
                        title: "Menu Bar Access",
                        description: "After the app starts, click the app icon in the menu bar to open the main window.",
                        icon: "menubar.rectangle",
                        color: theme.success,
                        customContent: {
                            AnyView(MenuBarDiagramView())
                        }
                    )
                } else if currentStep == 1 {
                    stepView(
                        title: "Network Filtering",
                        description: "Review every network connection request and choose whether to allow or deny each app.",
                        icon: "shield.checkered",
                        color: theme.warning,
                        customContent: {
                            AnyView(NetworkFilterDiagramView())
                        }
                    )
                } else if currentStep == 2 {
                    stepView(
                        title: "Toolbar Actions",
                        description: "The toolbar at the top provides common actions. More advanced options are in the overflow menu on the right.",
                        icon: "menubar.rectangle",
                        color: theme.primarySecondary,
                        customContent: {
                            AnyView(ToolbarDiagramView())
                        }
                    )
                } else {
                    stepView(
                        title: "How It Works",
                        description: "The system extension handles network filtering, and the app provides the user interface.",
                        icon: "gearshape.2.fill",
                        color: theme.info
                    ) {
                        AnyView(WorkingPrincipleDiagramView())
                    }
                }
            }
            .frame(maxHeight: .infinity)
            
            // 底部
            VStack(spacing: AppUI.Spacing.md) {
                // 进度指示器
                HStack(spacing: AppUI.Spacing.xs) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? theme.primary : theme.textSecondary.opacity(0.25))
                            .frame(width: 8, height: 8)
                    }
                }
                
                // 按钮
                HStack(spacing: AppUI.Spacing.md) {
                    if currentStep > 0 {
                        AppButton("Back", style: .secondary) {
                            currentStep -= 1
                        }
                    }
                    
                    Spacer()
                    
                    if currentStep < 3 {
                        AppButton("Next", style: .primary) {
                            currentStep += 1
                        }
                    } else {
                        AppButton("Get Started", style: .primary) {
                            closeWindow()
                        }
                    }
                }
                .padding(.horizontal, AppUI.Spacing.xl)
            }
            .padding(.bottom, AppUI.Spacing.xl)
        }
        .frame(width: 500, height: 600)
        .background(theme.background)
        .onAppear {
            resetToFirstStep()
        }
        // 监听关闭的通知
//        .onReceive(NotificationCenter.default.publisher(for: .shouldCloseWelcomeWindow)) { _ in 
//            closeWindow()
//        }
    }
    
    /**
     * 单个步骤视图
     */
    private func stepView(title: LocalizedStringKey, description: LocalizedStringKey, icon: String, color: Color, customContent: (() -> AnyView)? = nil) -> some View {
        VStack(spacing: AppUI.Spacing.lg) {
            if let customContent = customContent {
                customContent()
            } else {
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.appTitle)
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.appBody)
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppUI.Spacing.xl)
        }
    }
    

    
    /**
     * 重置到第一步
     * 确保每次打开引导界面时都从第一步开始
     */
    private func resetToFirstStep() {
        currentStep = 0
    }
    
    /**
     * 关闭窗口
     */
    private func closeWindow() {
        hasShownWelcome = true
        dismiss()
    }
}

/// 引导视图使用的产品名称。
public enum WelcomeGuideAppName {
    public static let name = "Netpause"
}
