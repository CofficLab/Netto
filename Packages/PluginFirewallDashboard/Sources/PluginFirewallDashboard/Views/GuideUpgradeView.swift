import SwiftUI
import ProviderSettingView

/**
 * 升级引导视图
 * 当免费用户达到限制时，引导用户升级到 Pro 版本
 */
struct UpgradeGuideView: View {
    @EnvironmentObject var ui: UIProvider
    
    var body: some View {
        Popview(
            iconName: "crown.fill",
            title: "升级到 Pro 版本",
            iconColor: .orange
        ) {
            VStack(spacing: 20) {
                // 限制提示区域
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 20, alignment: .center)
                        Text("已达到免费版限制")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.orange.opacity(0.1))
                    .cornerRadius(8)

                    HStack(spacing: 8) {
                        Image(systemName: "infinity")
                            .foregroundStyle(.green)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 20, alignment: .center)
                        Text("Pro 版本可无限制禁止应用")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.green.opacity(0.1))
                    .cornerRadius(8)
                }

                // 按钮组
                HStack(spacing: 12) {
                    Button("稍后再说") {
                        ui.hideUpgradeGuide()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("立即升级") {
                        openStoreWindow()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .font(.headline)
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
