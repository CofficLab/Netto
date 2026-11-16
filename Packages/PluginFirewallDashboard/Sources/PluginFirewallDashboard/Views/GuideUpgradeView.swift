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
            title: "升级到 Pro 版本",
            iconColor: .orange
        ) {
            VStack(spacing: AppUI.Spacing.md) {
                AppStatusBanner(kind: .warning, title: "已达到免费版限制")
                AppStatusBanner(kind: .info, title: "Pro 版本可无限制禁止应用")

                HStack(spacing: AppUI.Spacing.sm) {
                    AppButton("稍后再说", style: .secondary, fillsWidth: true) {
                        ui.hideUpgradeGuide()
                    }

                    AppButton("立即升级", systemImage: "crown.fill", style: .primary, fillsWidth: true) {
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
