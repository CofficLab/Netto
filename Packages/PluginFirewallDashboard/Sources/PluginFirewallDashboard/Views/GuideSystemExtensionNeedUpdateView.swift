import LumiUI
import ProviderFirewall
import ProviderViewEnvironment
import SwiftUI

struct SystemExtensionNeedUpdateView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "arrow.clockwise.circle",
            title: "需要更新系统扩展",
            iconColor: .orange
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                Text("检测到已安装旧版本的系统扩展，需要更新到当前版本")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                DashboardGuideSteps("更新步骤", steps: [
                    "点击下方按钮更新系统扩展",
                    "系统会自动替换旧版本扩展",
                    "等待更新完成，防火墙即可正常使用",
                ])

                DashboardInstallExtensionButton()
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Large") {
    DashboardPreviewHost {
        SystemExtensionNeedUpdateView()
    }
    .frame(width: 600, height: 1000)
}

#Preview("App - Small") {
    DashboardPreviewHost {
        SystemExtensionNeedUpdateView()
    }
    .frame(width: 600, height: 600)
}
