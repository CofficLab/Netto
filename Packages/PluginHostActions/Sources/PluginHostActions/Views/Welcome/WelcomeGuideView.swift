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
                
                Text("欢迎使用 \(WelcomeGuideAppName.name)")
                    .font(.appLargeTitle)
                    .foregroundStyle(theme.textPrimary)
                
                Text("网络过滤与监控工具")
                    .font(.appBody)
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(.top, AppUI.Spacing.xl)
            
            // 内容区域
            VStack(spacing: AppUI.Spacing.lg) {
                if currentStep == 0 {
                    stepView(
                        title: "菜单栏访问",
                        description: "应用运行后，您可以通过点击菜单栏中的应用图标来访问主界面。",
                        icon: "menubar.rectangle",
                        color: theme.success,
                        customContent: {
                            AnyView(MenuBarDiagramView())
                        }
                    )
                } else if currentStep == 1 {
                    stepView(
                        title: "网络过滤",
                        description: "您可以查看所有网络连接请求，并选择允许或拒绝特定的应用访问网络。",
                        icon: "shield.checkered",
                        color: theme.warning,
                        customContent: {
                            AnyView(NetworkFilterDiagramView())
                        }
                    )
                } else if currentStep == 2 {
                    stepView(
                        title: "工具栏操作",
                        description: "应用顶部的工具栏提供了各种功能，更多高级操作都集中在右侧的更多菜单按钮中。",
                        icon: "menubar.rectangle",
                        color: theme.primarySecondary,
                        customContent: {
                            AnyView(ToolbarDiagramView())
                        }
                    )
                } else {
                    stepView(
                        title: "工作原理",
                        description: "系统扩展负责网络过滤，应用程序提供用户界面。",
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
                        AppButton("上一步", style: .secondary) {
                            currentStep -= 1
                        }
                    }
                    
                    Spacer()
                    
                    if currentStep < 3 {
                        AppButton("下一步", style: .primary) {
                            currentStep += 1
                        }
                    } else {
                        AppButton("开始使用", style: .primary) {
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
    private func stepView(title: String, description: String, icon: String, color: Color, customContent: (() -> AnyView)? = nil) -> some View {
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
    public static let name = "TravelMode"
}
