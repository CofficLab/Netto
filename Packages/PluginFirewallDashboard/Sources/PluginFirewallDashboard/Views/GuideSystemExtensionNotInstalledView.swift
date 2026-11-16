import LumiUI
import ProviderFirewall
import ProviderViewEnvironment
import SwiftUI

struct SystemExtensionNotInstalledView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "exclamationmark.triangle",
            title: "系统扩展未安装",
            iconColor: .red
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                Text("系统扩展未安装，无法启动防火墙功能")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                DashboardGuideSteps("解决方案", steps: [
                    "点击下方按钮安装系统扩展",
                    "在弹出的对话框中点击「允许」",
                    "等待系统扩展安装完成",
                ])

                DashboardInstallExtensionButton()
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Large") {
    DashboardPreviewHost {
        SystemExtensionNotInstalledView()
    }
    .frame(width: 600, height: 1000)
}

#Preview("App - Small") {
    DashboardPreviewHost {
        SystemExtensionNotInstalledView()
    }
    .frame(width: 600, height: 600)
}
