import LumiUI
import SwiftUI

/// 公开工厂函数：为任意 `SettingViewProviding` 实现渲染设置界面。
///
/// 复刻 Lumi `makeSettingView(provider:)`：供自定义 Provider 在
/// `makeSettingView()` 中复用与 `DefaultSettingViewProviding` 一致的视图。
@MainActor
public func makeSettingView<Provider: SettingViewProviding>(
    provider: Provider
) -> AnyView {
    AnyView(SettingView(provider: provider))
}

/// 渲染「左侧入口列表 + 右侧详情视图」的设置界面。
///
/// 完整复刻 Lumi `ProviderSettingView.SettingView` 的视觉与交互，全部使用
/// **LumiUI 组件**（统一样式）：
/// - `AppSettingsSidebarShell` 双栏布局：固定宽侧边栏 + 分隔线 + 详情区
/// - 侧边栏 `AppSettingsSidebarContainer`（220pt）+ `AppSettingsSidebarItem`
///   （SF Symbol + 标题 + 选中高亮）
/// - 详情区 `AppSettingsDetailPane`（氛围渐变背景）
/// - 空状态与 Lumi 一致（gearshape + "Select a setting"）
/// - 通过 observer 观察 Provider 状态变化（`observationRevision`）刷新，
///   不重建侧边栏 ScrollView
///
/// 主题：宿主在启动时设置 `ChromeThemes.current`（如 `LumiFallbackChromeTheme`）
/// 使 LumiUI 组件渲染一致配色；未设置时组件回退到透明占位主题（不崩溃）。
struct SettingView<Provider: SettingViewProviding>: View {
    let provider: Provider
    @State private var observationRevision = 0
    @State private var observerHandle: (any SettingViewObserverHandle)?

    init(provider: Provider) {
        self.provider = provider
    }

    var body: some View {
        AppSettingsSidebarShell { sidebar } detail: { detail }
            .frame(minWidth: 720, minHeight: 460)
            .onAppear(perform: selectFirstEntryIfNeeded)
            .onAppear {
                guard observerHandle == nil else { return }
                observerHandle = provider.addSettingViewObserver { _ in
                    observationRevision += 1
                }
            }
            .onDisappear {
                observerHandle?.cancel()
                observerHandle = nil
            }
            // Provider 状态变化后刷新（选中/入口变化）。
            .onChange(of: observationRevision) { _, _ in }
    }

    /// 启动时若无选中入口则默认选中第一项。
    private func selectFirstEntryIfNeeded() {
        if provider.selectedEntryID == nil, let first = provider.entries.first {
            provider.selectEntry(id: first.id)
        }
    }

    /// 左侧：入口列表（LumiUI AppSettingsSidebarContainer + AppSettingsSidebarItem）。
    private var sidebar: some View {
        AppSettingsSidebarContainer(width: 220) {
            VStack(alignment: .leading, spacing: 10) {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(provider.entries) { entry in
                            AppSettingsSidebarItem(
                                title: entry.title,
                                systemImage: entry.systemImage,
                                isSelected: provider.selectedEntryID == entry.id
                            ) {
                                provider.selectEntry(id: entry.id)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    /// 右侧：详情区（LumiUI AppSettingsDetailPane；无选中时显示空状态）。
    private var detail: some View {
        AppSettingsDetailPane {
            if let id = provider.selectedEntryID,
               let entry = provider.entries.first(where: { $0.id == id }) {
                entry.makeDetailView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "Select a setting",
                    systemImage: "gearshape",
                    description: Text("从左侧选择一个设置入口")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
