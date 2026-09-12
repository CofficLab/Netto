import AppKit
import SwiftUI

/// 「设置」窗口 —— 通用设置面板（HostSettingsPlugin 贡献的 `general` 入口视图）。
///
/// 架构归属：插件贡献视图层。HostSettingsPlugin 在 `onBoot` 向
/// `SettingViewProviding` 注入 `SettingEntryItem(id: "general", ...)`，本视图
/// 作为该入口的详情视图（设置窗口右侧内容）；`FactoryNetto.makeSettingsView`
/// 解析 Provider 并渲染「左侧入口列表 + 右侧详情视图」（复刻 Lumi
/// `ProviderSettingView`），组合根只装配一次并缓存。
///
/// 依赖约束：
/// - 仅依赖 App target 常量（AppConfig）与系统框架（AppKit），不依赖任何
///   Provider 契约注入 —— entry 视图由 KernelCore 解析链提供，独立可渲染。
/// - 不创建任何核心服务；数据目录口径与 PersistenceConfig/AppConfig 一致
///   （Debug `~/Documents/debug`，Release 沙盒容器内 production）。
///
/// 线程/actor：`View`，body 求值无副作用；按钮动作在主线程执行。
struct GeneralSettingsView: View {
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
        Form {
            Section("通用") {
                dataFolderRow
            }

            Section("系统扩展") {
                openSystemSettingsRow
            }

            Section("关于") {
                aboutRow
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 420, minHeight: 360)
    }

    /// 数据目录行：显示路径 + 在访达中显示。
    private var dataFolderRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("数据目录")
                Text(dataFolder.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            Spacer()
            Button("在访达中显示") {
                NSWorkspace.shared.activateFileViewerSelecting([dataFolder])
            }
        }
        .padding(.vertical, 2)
    }

    /// 打开 macOS 系统设置中的网络扩展页（旧 BtnSetting 行为）。
    private var openSystemSettingsRow: some View {
        Button("打开系统设置") {
            if let url = URL(
                string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?extensionPointIdentifier=com.apple.system_extension.network_extension.extension-point"
            ) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    /// 关于行：应用名 + 版本/构建。
    private var aboutRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(AppConfig.appName)
                Text("版本 \(version) (\(build))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview("通用设置") {
    GeneralSettingsView()
}
