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
/// 复刻 Lumi `ProviderSettingView.SettingView` 的形态与交互：
/// - 双栏布局：固定宽侧边栏（220pt）+ 分隔线 + 详情区。
/// - 侧边栏列出全部 `entries`，选中项高亮（SF Symbol + 标题），
///   点击 `selectEntry(id:)` 切换右侧详情视图。
/// - 无选中入口时显示空状态（gearshape + "Select a setting"）。
/// - 通过 observer 观察 Provider 状态变化（`observationRevision`）刷新，
///   不重建侧边栏 ScrollView。
///
/// 泛型 `Provider` 支持任意 `SettingViewProviding` 实现。
struct SettingView<Provider: SettingViewProviding>: View {
    let provider: Provider
    @State private var observationRevision = 0
    @State private var observerHandle: (any SettingViewObserverHandle)?

    init(provider: Provider) {
        self.provider = provider
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detail
        }
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

    /// 左侧：入口列表。
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(provider.entries) { entry in
                        sidebarItem(entry)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(width: 220)
        }
        .padding(.vertical, 12)
        .background(.bar)
    }

    private func sidebarItem(_ entry: SettingEntryItem) -> some View {
        Button {
            provider.selectEntry(id: entry.id)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: entry.systemImage)
                    .frame(width: 18)
                Text(entry.title)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .font(.body)
            .foregroundStyle(provider.selectedEntryID == entry.id ? Color.accentColor : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background {
                if provider.selectedEntryID == entry.id {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor.opacity(0.12))
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// 右侧：详情区（选中入口的详情视图；无选中时显示空状态）。
    @ViewBuilder
    private var detail: some View {
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
