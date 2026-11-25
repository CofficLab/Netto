import LumiUI
import ProviderViewEnvironment
import ProviderAppSettings
import SwiftUI

/// 通用的应用信息显示组件，用于显示应用图标、名称、ID和事件数量
struct AppLine: View {
    @EnvironmentObject var ui: UIProvider
    @Environment(\.settingsProvider) private var repo: AppSettingsProviding?
    @LumiTheme private var theme

    var app: SmartApp

    @State var shouldAllow: Bool = true
    @State var hovering: Bool = false
    @State var popoverHovering: Bool = false
    @State var actionHovering: Bool = false
    @State private var hidePopoverTask: Task<Void, Never>?
    @State private var showPopoverTask: Task<Void, Never>?
    @State private var isChildrenExpanded: Bool = false

    /// 初始化应用信息视图
    /// - Parameters:
    ///   - app: 应用数据模型
    init(app: SmartApp) {
        self.app = app
    }

    var body: some View {
        AppListRow(accent: shouldAllow ? nil : theme.error) {
            HStack(spacing: 12) {
                AppIcon(app: app).frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.appBodyEmphasized)
                        .lineLimit(1)

                    Text(app.id)
                        .font(.appCaption)
                        .foregroundStyle(app.isSystemApp ? theme.warning : theme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer(minLength: 8)

                if hovering && app.isNotSample {
                    AppAction(shouldAllow: $shouldAllow, appId: app.id)
                        .onHover(perform: {
                            self.actionHovering = $0
                        })
                }
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("netto.app.row.\(app.id)")
            .onHover(perform: onHover)
        }
        .popover(isPresented: Binding(
            get: { ui.shouldShowPopover(for: app.id) && !self.actionHovering },
            set: { _ in }
        ), arrowEdge: .leading) {
            AppDetail(
                popoverHovering: $popoverHovering,
                app: app,
            ).frame(width: 600)
        }
        .onChange(of: self.popoverHovering) {
            handlePopoverHoverChange()
        }
        .onAppear(perform: onAppear)
    }
}

// MARK: - 事件

extension AppLine {
    /// 页面出现时的处理
    func onAppear() {
        guard let repo else { return }
        Task {
            self.shouldAllow = await repo.shouldAllow(app.id)
        }
    }

    /// 处理鼠标悬停状态变化
    /// - Parameter hovering: 是否悬停
    func onHover(_ hovering: Bool) {
        self.hovering = hovering

        if self.hovering {
            // 取消之前的隐藏任务
            hidePopoverTask?.cancel()
            hidePopoverTask = nil

            // 取消之前的显示任务
            showPopoverTask?.cancel()
            showPopoverTask = nil

            // 延迟显示 popover，避免过于敏感
            showPopoverTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms 延迟
                if !Task.isCancelled {
                    await MainActor.run {
                        self.ui.showPopover(for: self.app.id)
                    }
                }
            }
        } else {
            // 离开时取消显示任务
            showPopoverTask?.cancel()
            showPopoverTask = nil
            // 延迟隐藏popover，给用户时间移动到popover上
            // 只有当前显示的是这个应用的popover时才安排隐藏
            if ui.shouldShowPopover(for: self.app.id) {
                scheduleHidePopover()
            }
        }
    }

    /// 安排延迟隐藏popover
    private func scheduleHidePopover() {
        // 取消之前的隐藏任务
        hidePopoverTask?.cancel()

        // 创建新的延迟隐藏任务
        hidePopoverTask = Task {
            try? await Task.sleep(nanoseconds: 150000000) // 150ms延迟

            // 检查任务是否被取消
            if !Task.isCancelled {
                await MainActor.run {
                    // 只有当用户没有悬停在popover上且当前popover仍然是这个应用的时才隐藏
                    if !popoverHovering && ui.shouldShowPopover(for: self.app.id) {
                        ui.hidePopover()
                    }
                }
            }
        }
    }

    /// 处理popover悬停状态变化
    private func handlePopoverHoverChange() {
        if popoverHovering {
            // 用户悬停在popover上，取消隐藏任务
            hidePopoverTask?.cancel()
            hidePopoverTask = nil
        } else {
            // 用户离开popover，安排隐藏
            scheduleHidePopover()
        }
    }
}

#Preview {
    DashboardPreviewHost {
        ContentView()
    }
    .frame(width: 500)
    .frame(height: 600)
}
