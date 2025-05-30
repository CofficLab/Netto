import SwiftUI

/**
 * 工具栏示意图视图
 * 展示应用顶部工具栏和更多菜单的功能布局
 */
struct ToolbarDiagramView: View {
    @State private var showMoreMenu = false
    @State private var hoveredButton: String? = nil
    
    // 更多菜单选项
    private let moreMenuItems = [
        (icon: "puzzlepiece.extension", title: "安装", description: "安装网络过滤扩展"),
        (icon: "stop.circle", title: "停止", description: "停止网络监控"),
        (icon: "play.circle", title: "启动", description: "开始网络监控"),
        (icon: "gearshape", title: "打开系统设置", description: "配置系统扩展权限"),
        (icon: "questionmark.circle", title: "使用引导", description: "查看应用使用指南"),
        (icon: "info.circle", title: "关于", description: "查看应用信息"),
        (icon: "power", title: "退出", description: "退出应用程序")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // 工具栏示意图
            VStack(spacing: 12) {
                // 箭头指向更多菜单按钮（在工具栏上方）
                HStack {
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("点击这里")
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
                
                // 更多菜单（展开状态）
                if showMoreMenu {
                    moreMenuView
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            // 操作提示
            VStack(spacing: 8) {
            }
        }
        .padding(.vertical, 8)
    }
    
    /**
     * 工具栏视图
     * 模拟应用顶部的工具栏布局
     */
    private var toolbarView: some View {
        HStack(spacing: 12) {
            // 应用过滤器插件
            toolbarButton(icon: "line.3.horizontal.decrease.circle", title: "过滤器")
            
            // 事件列表插件
            toolbarButton(icon: "list.bullet.rectangle", title: "事件")
            
            // 消息插件
            toolbarButton(icon: "message.circle", title: "消息")
            
            // 开关插件
            toolbarButton(icon: "power.circle", title: "开关")
            
            Spacer()
            
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
                    Color.teal.opacity(0.1)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
}

#Preview {
    ToolbarDiagramView()
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .frame(height: 800)
}
