import KernelCore
import OSLog
import ProviderSettingView
import ProviderTheme
import SwiftUI

/// 复刻自 Lumi `PluginThemePack` 的主题包插件（单一插件批量注册 19 个
/// 主题 + 设置「外观」入口）。
///
/// 与 Lumi 的差异（Netto 无 ProviderCommand / KitLocalization）：
/// - 不注册命令菜单组（无 CommandProviding 契约）
/// - 本地化直接内联中文/英文（无 LumiPluginLocalization）
///
/// 生命周期：`onBoot(kernel:)` 解析 `ThemeProviding` 与 `SettingViewProviding`：
/// - 批量注册 `LegacyThemeCatalog.all`（19 个 `LumiTheme`，id 与旧版 Lumi 一致）
/// - 注册「外观」设置入口（order 2，位于「通用」之前），详情视图列出全部
///   主题供搜索/筛选/切换/预览
/// - `onShutdown` 注销入口并撤销全部主题贡献（当前选中回退由 Provider 处理）
///
/// 消费方通过 `ThemeProviding` 主题事件感知切换；渲染桥接（`@LumiTheme` /
/// `ChromeThemes`）由 FactoryNetto 层完成。
@MainActor
public final class ThemePackPlugin: KernelCore.SuperPlugin {
    nonisolated static let logger = Logger(subsystem: "com.yueyi.TravelMode.plugin.theme-pack", category: "ThemePack")

    public let id = "com.yueyi.TravelMode.plugin.theme-pack"
    public let order = 100
    public let metadata = KernelCore.PluginMetadata(
        name: "主题包",
        version: "1.0",
        policy: .enabledByDefault,
        summary: "批量注册 19 个复刻主题，并在设置中提供外观切换入口。"
    )

    private var themeObservation: ThemeSettingsObservationModel?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let theme = kernel.resolveProvider((any ThemeProviding).self) else {
            Self.logger.error("ThemeProviding 未注册，主题包跳过")
            return
        }
        for legacy in LegacyThemeCatalog.all {
            theme.registerTheme(legacy)
        }
        themeObservation?.cancel()
        let themeObservation = ThemeSettingsObservationModel(theme: theme)
        self.themeObservation = themeObservation

        // 设置入口：外观 / 主题选择（设置视图未注册时优雅降级）。
        if let settings = kernel.resolveProvider((any SettingViewProviding).self) {
            settings.addEntries([
                SettingEntryItem(
                    id: "appearance",
                    title: "外观",
                    systemImage: "paintpalette",
                    order: 2
                ) {
                    ThemeSettingsDetailView(theme: theme, observation: themeObservation)
                },
            ])
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        themeObservation?.cancel()
        themeObservation = nil
        if let theme = kernel.resolveProvider((any ThemeProviding).self) {
            for legacy in LegacyThemeCatalog.all {
                theme.unregisterTheme(id: legacy.id)
            }
        }
        kernel.resolveProvider((any SettingViewProviding).self)?
            .removeEntries(ids: ["appearance"])
    }

    /// 主题菜单名（保留 Lumi 语义；Netto 无命令菜单，供测试与将来复用）。
    static func localizedMenuName(locale: Locale = .current) -> String {
        locale.language.languageCode?.identifier == "zh" ? "主题" : "Theme"
    }
}
