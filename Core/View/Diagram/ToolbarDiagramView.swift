import SwiftUI

/**
 * 工具栏示意图视图
 * 展示应用顶部工具栏和更多菜单的功能布局
 */
struct ToolbarDiagramView: View {
    @State private var showMoreMenu = false
    @State private var hoveredButton: String? = nil
    @State private var hoveredAppIndex: Int? = nil
    @State private var allowedStates: [Bool] = [true, false, true]

    // 更多菜单选项
    private let moreMenuItems = [
        (icon: "puzzlepiece.extension", title: "安装", description: "安装网络过滤扩展"),
        (icon: "stop.circle", title: "停止", description: "停止网络监控"),
        (icon: "play.circle", title: "启动", description: "开始网络监控"),
        (icon: "gearshape", title: "打开系统设置", description: "配置系统扩展权限"),
        (icon: "questionmark.circle", title: "使用引导", description: "查看应用使用指南"),
        (icon: "info.circle", title: "关于", description: "查看应用信息"),
        (icon: "power", title: "退出", description: "退出应用程序"),
    ]

    // 模拟应用数据
    private let mockApps = [
        (name: "Safari", id: "com.apple.Safari", icon: "safari", events: 15),
        (name: "Chrome", id: "com.google.Chrome", icon: "globe", events: 8),
        (name: "Xcode", id: "com.apple.dt.Xcode", icon: "hammer", events: 3),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 工具栏示意图
            VStack(spacing: 12) {
                // 箭头指向更多菜单按钮（在工具栏上方）
                HStack {
                    VStack(spacing: 4) {
                        Text("开关")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .fontWeight(.bold)

                        // 向下指向的箭头
                        Image(systemName: "arrow.down")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.purple)
                            .scaleEffect(1.2)
                    }
                    .offset(x: 16)

                    Spacer()
                    VStack(spacing: 4) {
                        Text("日志")
                            .font(.caption)
                            .foregroundColor(.cyan)
                            .fontWeight(.bold)

                        // 向下指向的箭头
                        Image(systemName: "arrow.down")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.cyan)
                            .scaleEffect(1.2)
                    }
                    .offset(x: -22)

                    VStack(spacing: 4) {
                        Text("更多操作")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.bold)

                        // 向下指向的箭头
                        Image(systemName: "arrow.down")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.orange)
                            .scaleEffect(1.2)
                    }
                    .offset(x: -16) // 调整位置使箭头对准更多菜单按钮
                }
                .frame(width: 350)

                // 顶部工具栏
                toolbarView

                // 更多菜单
                if showMoreMenu {
                    moreMenuView
                        .transition(.scale.combined(with: .opacity))
                }
            }

            if !showMoreMenu {
                appListView
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    /**
     * 工具栏视图
     * 模拟应用顶部的工具栏布局
     */
    private var toolbarView: some View {
        HStack(spacing: 20) {
            // 开关插件
            toolbarButton(icon: "power.circle", title: "开关")

            Spacer()

            // 事件列表插件
            toolbarButton(icon: "list.bullet.rectangle", title: "事件")

            // 更多菜单按钮（重点突出）
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showMoreMenu.toggle()
                }
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 24)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.red]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.orange, lineWidth: 2)
                    )
                    .scaleEffect(hoveredButton == "more" ? 1.1 : 1.0)
                    .shadow(color: .orange.opacity(0.5), radius: hoveredButton == "more" ? 8 : 4)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    hoveredButton = hovering ? "more" : nil
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.teal.opacity(0.2),
                    Color.teal.opacity(0.1),
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .frame(width: 350)
    }

    /**
     * 工具栏按钮组件
     * @param icon SF Symbol图标名称
     * @param title 按钮标题
     */
    private func toolbarButton(icon: String, title: String) -> some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .frame(width: 24, height: 24)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(PlainButtonStyle())
        .help(title)
    }

    /**
     * 更多菜单视图
     * 展示弹出菜单中的所有功能选项
     */
    private var moreMenuView: some View {
        VStack(spacing: 0) {
            ForEach(Array(moreMenuItems.enumerated()), id: \.offset) { index, item in
                moreMenuItem(item: item, index: index)

                if index < moreMenuItems.count - 1 {
                    Divider()
                        .padding(.horizontal, 12)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .frame(width: 280)
    }

    /**
     * 更多菜单项组件
     * @param item 菜单项数据
     * @param index 项目索引
     */
    private func moreMenuItem(item: (icon: String, title: String, description: String), index: Int) -> some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                // 图标
                Image(systemName: item.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                // 文本信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)

                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                hoveredButton == "menu_\(index)" ?
                    Color.accentColor.opacity(0.1) : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredButton = hovering ? "menu_\(index)" : nil
            }
        }
    }

    /**
     * 应用列表视图
     */
    private var appListView: some View {
        VStack(spacing: 16) {
            // 应用列表
            VStack(spacing: 0) {
                ForEach(Array(mockApps.enumerated()), id: \.offset) { index, app in
                    mockAppLine(app: app, index: index)

                    if index < mockApps.count - 1 {
                        Divider()
                    }
                }
            }
            .frame(width: 350)
        }
    }

    /**
     * 模拟应用行视图
     * 复制AppLine的交互效果和视觉样式
     * @param app 应用数据
     * @param index 应用索引
     */
    private func mockAppLine(app: (name: String, id: String, icon: String, events: Int), index: Int) -> some View {
        HStack {
            // 应用图标
            Image(systemName: app.icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // 应用信息
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 14, weight: .medium))

                HStack(spacing: 4) {
                    Text("\(app.events)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(app.id)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // 操作按钮（hover时显示）
            if hoveredAppIndex == index {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        allowedStates[index].toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: allowedStates[index] ? "xmark.circle.fill" : "checkmark.circle.fill")
                        Text(allowedStates[index] ? "禁止" : "允许")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(allowedStates[index] ? Color.red : Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Group {
                if !allowedStates[index] {
                    // 被禁止的应用显示红色背景
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.red.opacity(0.2),
                            Color.red.opacity(0.05),
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else if hoveredAppIndex == index {
                    // hover状态显示薄荷绿背景
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
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredAppIndex = hovering ? index : nil
            }
        }
        .frame(height: 50)
    }
}

#Preview {
    ToolbarDiagramView()
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .frame(height: 800)
}
