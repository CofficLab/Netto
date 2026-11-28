import LumiUI
import ProviderSettingView
import SwiftUI

/**
 * 升级引导视图
 * 当免费用户达到限制时，引导用户升级到 Pro 版本
 */
struct UpgradeGuideView: View {
    @EnvironmentObject var ui: UIProvider

    var body: some View {
        DashboardGuidePanel(
            iconName: "crown.fill",
            title: "Upgrade to Pro",
            iconColor: .orange
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                AppStatusBanner(kind: .warning, title: "Free Plan Limit Reached")
                AppStatusBanner(kind: .info, title: "Pro lets you block unlimited apps")

                HStack(spacing: AppUI.Spacing.sm) {
                    AppButton("Not Now", style: .secondary, fillsWidth: true) {
                        ui.hideUpgradeGuide()
                    }

                    AppButton("Upgrade Now", systemImage: "crown.fill", style: .primary, fillsWidth: true) {
                        openStoreWindow()
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func openStoreWindow() {
        // 商店已迁入设置窗口：直接深链到「商店」入口，替代旧的独立商店窗口。
        NotificationCenter.default.post(
            name: SettingViewNavigation.openSettingsNotification,
            object: nil,
            userInfo: [SettingViewNavigation.entryIDUserInfoKey: "store"]
        )
        // 关闭升级引导界面
        ui.hideUpgradeGuide()
    }
}

// MARK: - Preview

#Preview("App - Large") {
    UpgradeGuideView()
        .dashboardPreviewRoot()
        .frame(width: 600, height: 500)
}

#Preview("App - Small") {
    UpgradeGuideView()
        .dashboardPreviewRoot()
        .frame(width: 600, height: 500)
}
