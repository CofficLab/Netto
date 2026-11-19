import LumiUI
import SwiftUI

/// 需要在系统设置中调整状态时的通用引导（过滤器被禁用、权限被拒绝等）。
struct SystemSettingsGuideView: View {
    let title: String
    let message: String
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
            title: "防火墙已禁用",
            message: "过滤器在系统设置中被禁用，启用后才能拦截未授权联网。",
            iconName: "shield.slash"
        )
    }
    .frame(height: 500)
}
