import SwiftUI

/// 通用的应用信息显示组件，用于显示应用图标、名称、ID和事件数量
/// 支持紧凑模式和普通模式，可自定义字体大小和样式
struct AppInfo: View {
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var ui: UIProvider

    var app: SmartApp
    var iconSize: CGFloat
    var nameFont: Font
    var idFont: Font
    var countFont: Font
    var isCompact: Bool
    var copyMessageDuration: Double
    var copyMessageText: String

    @State var shouldAllow: Bool = true
    @State var hovering: Bool = false
    @State var showCopyMessage: Bool = false
    @State var showChildrenPopover: Bool = false
    @State var popoverHovering: Bool = false

    /// 初始化应用信息视图
    /// - Parameters:
    ///   - app: 应用数据模型
    ///   - iconSize: 图标大小
    ///   - nameFont: 应用名称字体
    ///   - idFont: 应用ID字体
    ///   - countFont: 事件数量字体
    ///   - isCompact: 是否为紧凑模式
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
        self.isCompact = isCompact
        self.copyMessageDuration = copyMessageDuration
        self.copyMessageText = copyMessageText
    }

    var body: some View {
        HStack(spacing: isCompact ? 8 : 12) {
            app.getIcon().frame(width: iconSize, height: iconSize)

            VStack(alignment: .leading, spacing: isCompact ? 2 : 4) {
                HStack {
                    Text(app.name)
                        .font(nameFont)
                        .lineLimit(1)

                    if !app.children.isEmpty && !isCompact {
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
                        .foregroundColor(app.isSystemApp ? .orange.opacity(0.7) : (isCompact ? .secondary : .primary))
                        .lineLimit(1)
                        .truncationMode(isCompact ? .middle : .tail)
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
        .popover(isPresented: $showChildrenPopover, arrowEdge: .leading) {
            AppDetail(
                popoverHovering: $popoverHovering,
                app: app,
            ).frame(width: 600)
        }
        .onChange(of: self.popoverHovering, {
            self.showChildrenPopover = self.popoverHovering
        })
        .onAppear(perform: onAppear)
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(background)
        .overlay(
            Group {
                if showCopyMessage {
                    Text(copyMessageText)
                        .font(isCompact ? .caption2 : .caption)
                        .padding(.horizontal, isCompact ? 6 : 8)
                        .padding(.vertical, isCompact ? 3 : 4)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(isCompact ? 4 : 6)
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

    func onHover(_ hovering: Bool) {
        self.hovering = hovering
        if self.hovering {
            self.ui.setHoveredAppId(self.app.id)
            self.showChildrenPopover = true
        } else {
            if self.ui.hoveredAppId != self.app.id {
                showChildrenPopover = false
                return
            }

            // 延迟关闭，给用户时间移动到popover
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if self.ui.hoveredAppId != self.app.id {
                    showChildrenPopover = false
                    return
                }
                if !popoverHovering {
                    showChildrenPopover = false
                }
            }
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}
