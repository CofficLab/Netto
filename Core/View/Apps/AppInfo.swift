import SwiftUI

/// 通用的应用信息显示组件，用于显示应用图标、名称、ID和事件数量
struct AppInfo: View {
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var ui: UIProvider

    var app: SmartApp
    var iconSize: CGFloat
    var nameFont: Font
    var idFont: Font
    var countFont: Font
    var copyMessageDuration: Double
    var copyMessageText: String

    @State var shouldAllow: Bool = true
    @State var hovering: Bool = false
    @State var showCopyMessage: Bool = false
    @State var popoverHovering: Bool = false
    @State private var hidePopoverTask: Task<Void, Never>?

    /// 初始化应用信息视图
    /// - Parameters:
    ///   - app: 应用数据模型
    ///   - iconSize: 图标大小
    ///   - nameFont: 应用名称字体
    ///   - idFont: 应用ID字体
    ///   - countFont: 事件数量字体
    ///   - copyMessageDuration: 复制提示显示时长
    ///   - copyMessageText: 复制提示文本
    ///   - shouldAllow: 是否允许应用运行的绑定
    ///   - hovering: 鼠标悬停状态的绑定
    ///   - showCopyMessage: 显示复制消息状态的绑定
    init(
        app: SmartApp,
        iconSize: CGFloat,
        nameFont: Font = .body,
        idFont: Font = .callout,
        countFont: Font = .callout,
        isCompact: Bool = false,
        copyMessageDuration: Double = 2.0,
        copyMessageText: String = "App ID 已复制到剪贴板",
    ) {
        self.app = app
        self.iconSize = iconSize
        self.nameFont = nameFont
        self.idFont = idFont
        self.countFont = countFont
        self.copyMessageDuration = copyMessageDuration
        self.copyMessageText = copyMessageText
    }

    var body: some View {
        HStack(spacing: 12) {
            app.getIcon().frame(width: iconSize, height: iconSize)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(app.name)
                        .font(nameFont)
                        .lineLimit(1)

                    if !app.children.isEmpty {
                        Text("(\(app.children.count) children)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(alignment: .top, spacing: 4) {
                    Text("\(app.events.count)")
                        .font(countFont)

                    Text(app.id)
                        .font(idFont)
                        .foregroundColor(app.isSystemApp ? .orange.opacity(0.7) : .primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer()

            if hovering && app.isNotSample {
                AppAction(shouldAllow: $shouldAllow, appId: app.id)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            copyAppId()
        }
        .onHover(perform: onHover)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .popover(isPresented: Binding(
            get: { ui.shouldShowPopover(for: app.id) },
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
        .overlay(
            Group {
                if showCopyMessage {
                    Text(copyMessageText)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical,  4)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius( 6)
                        .transition(.opacity.combined(with: .scale))
                }
            },
            alignment: .center
        )
    }

    /// 复制应用 ID 到剪贴板
    func copyAppId() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(app.id, forType: .string)

        // 显示复制成功提示
        withAnimation(.easeInOut(duration: 0.3)) {
            showCopyMessage = true
        }

        // 指定时间后隐藏提示
        DispatchQueue.main.asyncAfter(deadline: .now() + copyMessageDuration) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showCopyMessage = false
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
            self.ui.setHoveredAppId(self.app.id)
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
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms延迟
            
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
    RootView {
        ContentView()
    }
    .frame(height: 600)
}
