import LumiUI
import SwiftUI

/// 设置窗口侧边栏顶部的 Header：应用 Logo（64×64）+ 名称 + 版本。
///
/// 复刻 Lumi `PluginSettingView.HeaderView`：使用 `AppSettingsSidebarHeader`
/// 统一排版。Netto 无 `LogoProviding` 契约，Logo 回退到主题色 `app.fill`
/// 图标（对应 Lumi 未注册 Logo 时的分支）。
///
/// 数据来源：`AppBundleInfo` 从主 Bundle 读取应用名 / 版本 / 构建号
/// （与 GeneralSettingsView 的「关于」行一致）。
struct HeaderView: View {
    @LumiTheme private var theme

    private let appInfo = AppBundleInfo()

    var body: some View {
        AppSettingsSidebarHeader(
            name: appInfo.name,
            version: appInfo.version,
            build: appInfo.build,
            topSpacing: 22,
            bottomSpacing: 8
        ) {
            HStack {
                Spacer()
                Image(systemName: "app.fill")
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 64, height: 64)
                Spacer()
            }
        }
    }
}

/// 主 Bundle 的应用信息（名称 / 版本 / 构建号）。
///
/// 线程/actor：`Bundle.main` 只读，任一线程安全。
struct AppBundleInfo {
    var name: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "TravelMode"
    }

    var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}

#Preview("Settings Sidebar Header") {
    HeaderView()
        .frame(width: 220)
        .padding()
}
