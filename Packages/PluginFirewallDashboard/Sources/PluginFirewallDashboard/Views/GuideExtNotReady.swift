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
                    "找到本应用的扩展",
                    "将开关点击到启用状态",
                ])

                DashboardOpenSystemSettingsButton()
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
