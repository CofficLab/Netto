import AppKit
import LumiUI
import ProviderPersistence
import SwiftUI

/// 「设置」窗口 —— 通用设置面板（HostSettingsPlugin 贡献的 `general` 入口视图）。
///
/// 架构归属：插件贡献视图层。HostSettingsPlugin 在 `onBoot` 向
/// `SettingViewProviding` 注入 `SettingEntryItem(id: "general", ...)`，本视图
/// 作为该入口的详情视图（设置窗口右侧内容）；共享窗口壳
/// 解析 Provider 并渲染「左侧入口列表 + 右侧详情视图」（复刻 Lumi
/// `ProviderSettingView`），组合根只装配一次并缓存。
///
/// 样式：与 Lumi / JuiceNote / Wakey 的通用设置页同构 ——
/// `AppSettingsContentScaffold` + `AppSettingSection` + `AppSettingRow`，
/// 行尾统一用 `AppButton(.secondary, .small)`；不再为每个分组额外套 `AppCard`
/// （`AppSettingSection` 在 macOS 已自带卡片）。
///
/// 「使用引导」：通用页的「使用引导」行以 sheet 展示 `WelcomeGuideView`
/// （与启动欢迎窗共用同一视图，`hasShownWelcome` 键与旧实现一致）。
///
/// 依赖约束：
/// - 依赖持久化路径配置、LumiUI 组件与系统框架（AppKit），
///   不依赖任何 Provider 契约注入 —— entry 视图由 KernelCore 解析链提供。
/// - 数据目录由 `HostSettingsPlugin` 从 `StorageProviding` 注入
///   （`<App Support>/<bundleID>/db_<debug|production>_v<主版本>/`），
///   不再自行拼接 Documents 路径。
///
/// 线程/actor：`View`，body 求值无副作用；按钮动作在主线程执行。
struct GeneralSettingsView: View {
    /// 是否展示「使用引导」sheet（点击通用页「使用引导」行置位）。
    @State private var showGuide = false

    /// App bundle 元数据（名称 / 包名 / 版本 / 构建）。
    private let bundleInfo = AppBundleInfo()

    /// 数据根目录（由插件从 `StorageProviding` 注入；nil 时显示占位）。
    private let dataRootDirectory: URL?

    init(dataRootDirectory: URL? = nil) {
        self.dataRootDirectory = dataRootDirectory
    }

    var body: some View {
        AppSettingsContentScaffold(maxContentWidth: nil) {
            VStack(alignment: .leading, spacing: AppUI.Spacing.lg) {
                guideSection
                appSection
                systemExtensionSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // 「使用引导」sheet：尺寸与启动欢迎窗一致（500x600），
        // WelcomeGuideView 的「开始使用」按钮经 @Environment(\.dismiss) 关闭 sheet。
        .sheet(isPresented: $showGuide) {
            WelcomeGuideView()
                .frame(width: 500, height: 600)
        }
    }

    // MARK: - Sections

    /// 使用引导：打开应用各功能的使用说明。
    private var guideSection: some View {
        AppSettingSection(title: "使用引导", titleAlignment: .leading) {
            AppSettingRow(
                title: "使用引导",
                description: "查看应用各功能的使用说明",
                icon: "book"
            ) {
                AppButton(
                    "打开",
                    systemImage: "book.pages",
                    style: .secondary,
                    size: .small
                ) {
                    showGuide = true
                }
            }
        }
    }

    /// 应用信息：名称、Bundle ID、版本、构建与数据目录。
    private var appSection: some View {
        AppSettingSection(title: PersistenceConfig.appName, titleAlignment: .leading) {
            VStack(spacing: 0) {
                AppSettingRow(
                    title: "名称",
                    description: bundleInfo.name,
                    icon: "app"
                ) {
                    EmptyView()
                }

                divider

                AppSettingRow(
                    title: "Bundle ID",
                    description: bundleInfo.bundleIdentifier,
                    icon: "number"
                ) {
                    EmptyView()
                }

                divider

                AppSettingRow(
                    title: "版本",
                    description: bundleInfo.version ?? "—",
                    icon: "info.circle"
                ) {
                    EmptyView()
                }

                divider

                AppSettingRow(
                    title: "构建",
                    description: bundleInfo.build ?? "—",
                    icon: "hammer"
                ) {
                    EmptyView()
                }

                divider

                AppSettingRow(
                    title: "数据目录",
                    description: dataRootDirectory?.path ?? "—",
                    icon: "folder"
                ) {
                    AppButton(
                        "打开",
                        systemImage: "folder",
                        style: .secondary,
                        size: .small
                    ) {
                        guard let dataRootDirectory else { return }
                        NSWorkspace.shared.activateFileViewerSelecting([dataRootDirectory])
                    }
                }
            }
        }
    }

    /// 系统扩展：跳转系统设置中的网络扩展页。
    private var systemExtensionSection: some View {
        AppSettingSection(title: "系统扩展", titleAlignment: .leading) {
            AppSettingRow(
                title: "网络扩展",
                description: "打开系统设置中的网络扩展页",
                icon: "puzzlepiece.extension"
            ) {
                AppButton(
                    "打开",
                    systemImage: "arrow.up.forward.app",
                    style: .secondary,
                    size: .small,
                    action: openSystemSettings
                )
            }
        }
    }

    private var divider: some View {
        Divider()
            .padding(.vertical, AppUI.Spacing.xs)
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
        .frame(width: 640, height: 600)
}
