import MagicCore
import SwiftUI

/// 通用的应用信息显示组件，用于显示应用图标、名称、ID和事件数量
struct AppInfo: View {
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var ui: UIProvider

    var app: SmartApp

    @State var shouldAllow: Bool = true
    @State var hovering: Bool = false
    @State var popoverHovering: Bool = false
    @State var actionHovering: Bool = false
    @State private var hidePopoverTask: Task<Void, Never>?
    @State private var isChildrenExpanded: Bool = false

    /// 初始化应用信息视图
    /// - Parameters:
    ///   - app: 应用数据模型
    init(app: SmartApp) {
        self.app = app
    }

    var body: some View {
        VStack(spacing: 0) {
            // 主应用信息
            HStack(spacing: 12) {
                app.getIcon().frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(app.name)
                            .font(.body)
                            .lineLimit(1)

                        if !app.children.isEmpty {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isChildrenExpanded.toggle()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: isChildrenExpanded ? "chevron.down" : "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("\(app.children.count) children")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help(isChildrenExpanded ? "收起子程序" : "展开子程序")
                        }
                    }

                    HStack(alignment: .top, spacing: 4) {
                        Text("\(app.events.count)")
                            .font(.callout)

                        Text(app.id)
                            .font(.callout)
                            .foregroundColor(app.isSystemApp ? .orange.opacity(0.7) : .primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }

                Spacer()

                if hovering && app.isNotSample {
                    AppAction(shouldAllow: $shouldAllow, appId: app.id)
                        .onHover(perform: {
                            self.actionHovering = $0
                        })
                }
            }
            .contentShape(Rectangle())
            .onHover(perform: onHover)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(background)

            // 子程序列表（可折叠）
            if isChildrenExpanded && !app.children.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(app.children.enumerated()), id: \.element.id) { index, childApp in
                        ChildAppRow(childApp: childApp)

                        if index < app.children.count - 1 {
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - View

extension AppInfo {
    var background: some View {
        Group {
            if !shouldAllow {
                if hovering {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.red.opacity(0.4),
                            Color.mint.opacity(0.1),
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.red.opacity(0.2),
                            Color.red.opacity(0.05),
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            } else if hovering {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.mint.opacity(0.2),
                        Color.mint.opacity(0.05),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
    }
}

// MARK: - 事件

extension AppInfo {
    /// 页面出现时的处理
    func onAppear() {
        self.shouldAllow = data.shouldAllow(app.id)
    }

    /// 处理鼠标悬停状态变化
    /// - Parameter hovering: 是否悬停
    func onHover(_ hovering: Bool) {
        self.hovering = hovering

        if self.hovering {
            // 取消之前的隐藏任务
            hidePopoverTask?.cancel()
            hidePopoverTask = nil

            // 设置当前悬停的应用ID并显示popover
            self.ui.showPopover(for: self.app.id)
        } else {
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

/// 子应用行组件，支持hover和详情展示
struct ChildAppRow: View {
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var ui: UIProvider

    let childApp: SmartApp

    @State private var hovering: Bool = false
    @State private var popoverHovering: Bool = false
    @State private var hidePopoverTask: Task<Void, Never>?
    @State private var shouldAllow: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            // 缩进指示器
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 2, height: 20)
                .padding(.leading, 20)

            childApp.getIcon().frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(childApp.name)
                    .font(.caption)
                    .lineLimit(1)

                HStack(alignment: .top, spacing: 4) {
                    Text("\(childApp.events.count)")
                        .font(.caption2)

                    Text(childApp.id)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer()

            if hovering && childApp.isNotSample {
                AppAction(shouldAllow: $shouldAllow, appId: childApp.id)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 10)
        .background(hovering ? Color.secondary.opacity(0.1) : Color.secondary.opacity(0.05))
        .contentShape(Rectangle())
        .onHover(perform: onHover)
        .popover(isPresented: Binding(
            get: { ui.shouldShowPopover(for: childApp.id) },
            set: { _ in }
        ), arrowEdge: .leading) {
            AppDetail(
                popoverHovering: $popoverHovering,
                app: childApp
            ).frame(width: 600)
        }
        .onChange(of: self.popoverHovering) {
            handlePopoverHoverChange()
        }
        .onAppear {
            self.shouldAllow = data.shouldAllow(childApp.id)
        }
    }

    /// 处理鼠标悬停状态变化
    /// - Parameter hovering: 是否悬停
    private func onHover(_ hovering: Bool) {
        self.hovering = hovering

        if self.hovering {
            // 取消之前的隐藏任务
            hidePopoverTask?.cancel()
            hidePopoverTask = nil

            // 设置当前悬停的应用ID并显示popover
            self.ui.showPopover(for: self.childApp.id)
        } else {
            // 延迟隐藏popover，给用户时间移动到popover上
            if ui.shouldShowPopover(for: self.childApp.id) {
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
                    if !popoverHovering && ui.shouldShowPopover(for: self.childApp.id) {
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
    RootView {
        ContentView()
    }
    .frame(height: 600)
}
