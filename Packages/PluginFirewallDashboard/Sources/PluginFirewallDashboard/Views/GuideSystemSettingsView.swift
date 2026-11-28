import LumiUI
import SwiftUI

/// 需要在系统设置中调整状态时的通用引导（过滤器被禁用、权限被拒绝等）。
struct SystemSettingsGuideView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var iconName = "exclamationmark.shield"
    var iconColor: Color = .orange

    var body: some View {
        DashboardGuidePanel(iconName: iconName, title: title, iconColor: iconColor) {
            VStack(spacing: AppUI.Spacing.md) {
                Text(message)
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                DashboardOpenSystemSettingsButton()
            }
        }
    }
}

#Preview {
    DashboardPreviewHost {
        SystemSettingsGuideView(
            title: "Firewall Disabled",
            message: "The filter is disabled in System Settings. Enable it to block unauthorized network access.",
            iconName: "shield.slash"
        )
    }
    .frame(height: 500)
}
