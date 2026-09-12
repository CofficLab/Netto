import AppKit
import LumiUI
import SwiftUI

/// 「设置」窗口 —— 通用设置面板（HostSettingsPlugin 贡献的 `general` 入口视图）。
///
/// 架构归属：插件贡献视图层。HostSettingsPlugin 在 `onBoot` 向
/// `SettingViewProviding` 注入 `SettingEntryItem(id: "general", ...)`，本视图
/// 作为该入口的详情视图（设置窗口右侧内容）；`FactoryNetto.makeSettingsView`
/// 解析 Provider 并渲染「左侧入口列表 + 右侧详情视图」（复刻 Lumi
/// `ProviderSettingView`），组合根只装配一次并缓存。
///
/// 样式：自 v2 起全部使用 **LumiUI 组件**（`AppCard` + `AppSettingsSection`
/// + `AppSettingRow`，与 Lumi 插件设置页同构）以统一视觉；主题由 LumiUI 内置
/// `LumiDefaultTheme`（森林墨）兜底，宿主启动时另设 `ChromeThemes.current`
/// 为 `LumiFallbackChromeTheme` 供氛围背景使用。
///
/// 「使用引导」入口：通用卡片内新增「使用引导」行（复刻 Lumi 设置页
/// `AppSettingRow` 动作行形态），点击以 sheet 展示 `WelcomeGuideView`
/// （使用引导步骤，无 Provider 环境依赖、不创建核心服务；与启动欢迎窗
/// 共用同一视图，`hasShownWelcome` 键与旧实现一致）。
///
/// 依赖约束：
/// - 仅依赖 App target 常量（AppConfig）、LumiUI 组件与系统框架（AppKit），
///   不依赖任何 Provider 契约注入 —— entry 视图由 KernelCore 解析链提供。
/// - 不创建任何核心服务；数据目录口径与 PersistenceConfig/AppConfig 一致
///   （Debug `~/Documents/debug`，Release 沙盒容器内 production）。
///
/// 线程/actor：`View`，body 求值无副作用；按钮动作在主线程执行。
struct GeneralSettingsView: View {
    /// 是否展示「使用引导」sheet（点击通用卡片「使用引导」行置位）。
    @State private var showGuide = false

    /// 数据目录（与 AppConfig.databaseFolder 一致）。
    private var dataFolder: URL { AppConfig.databaseFolder }

    /// 版本号（CFBundleShortVersionString）。
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    /// 构建号（CFBundleVersion）。
    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AppCard {
                AppSettingsSection(title: "通用", spacing: 12) {
                    AppSettingRow(
                        title: "使用引导",
                        description: "查看应用使用说明",
                        icon: "graduationcap.fill",
                        action: { showGuide = true }
                    ) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    AppSettingRow(
                        title: "数据目录",
                        description: dataFolder.path,
                        icon: "folder"
                    ) {
                        Button("在访达中显示") {
                            NSWorkspace.shared.activateFileViewerSelecting([dataFolder])
                        }
                    }
                }
            }

            AppCard {
                AppSettingsSection(title: "系统扩展", spacing: 12) {
                    AppSettingRow(
                        title: "网络扩展",
                        description: "打开系统设置中的网络扩展页",
                        icon: "puzzlepiece.extension",
                        action: openSystemSettings
                    ) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            AppCard {
                AppSettingsSection(title: "关于", spacing: 12) {
                    AppSettingRow(
                        title: AppConfig.appName,
                        description: "版本 \(version) (\(build))",
                        icon: "info.circle"
                    ) {}
                }
            }
        }
        .padding(16)
        .frame(minWidth: 420, minHeight: 360, alignment: .topLeading)
        // 「使用引导」sheet：尺寸与启动欢迎窗一致（500x600），
        // WelcomeGuideView 的「开始使用」按钮经 @Environment(\.dismiss) 关闭 sheet。
        .sheet(isPresented: $showGuide) {
            WelcomeGuideView()
                .frame(width: 500, height: 600)
        }
    }

    /// 打开 macOS 系统设置中的网络扩展页（旧 BtnSetting 行为）。
    private func openSystemSettings() {
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?extensionPointIdentifier=com.apple.system_extension.network_extension.extension-point"
        ) {
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview("通用设置") {
    GeneralSettingsView()
}
