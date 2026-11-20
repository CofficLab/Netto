import LumiUI
import ProviderFirewall
import ProviderViewEnvironment
import SwiftUI

public struct ExtensionNotReady: View {
    public init() {}

    public var body: some View {
        DashboardGuidePanel(
            iconName: "exclamationmark.shield",
            title: "需要激活系统扩展",
            iconColor: .orange
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                DashboardGuideSteps("激活步骤", steps: [
                    "打开系统设置",
                    "找到本应用的扩展（若没有条目，点击下方重新安装）",
                    "将开关点击到启用状态",
                ])

                VStack(spacing: AppUI.Spacing.sm) {
                    DashboardOpenSystemSettingsButton()
                    // 扩展未注册时系统设置里不会有条目，提供重新注册入口避免死循环。
                    DashboardInstallExtensionButton(
                        title: "重新安装扩展",
                        busyTitle: "正在提交…",
                        style: .secondary
                    )
                }
            }
        }
    }
}

#Preview {
    ExtensionNotReady()
        .dashboardPreviewRoot()
        .frame(height: 500)
}

#Preview("App") {
    DashboardPreviewHost {
        ContentView()
    }
    .frame(height: 800)
}
