import SwiftUI

/**
 * 网络过滤示意图视图
 * 模拟应用列表的交互效果，展示hover状态下的操作按钮和背景色变化
 */
struct NetworkFilterDiagramView: View {
    @State private var hoveredIndex: Int? = nil
    @State private var allowedStates: [Bool] = [true, false, true, false]

    // 模拟应用数据
    private let mockApps = [
        (name: "Safari", id: "com.apple.Safari", icon: "safari", events: 15),
        (name: "Chrome", id: "com.google.Chrome", icon: "globe", events: 8),
        (name: "Xcode", id: "com.apple.dt.Xcode", icon: "hammer", events: 3),
    ]

    var body: some View {
        VStack(spacing: 16) {
            // 应用列表示意图
            VStack(spacing: 0) {
                ForEach(Array(mockApps.enumerated()), id: \.offset) { index, app in
                    mockAppLine(app: app, index: index)

                    if index < mockApps.count - 1 {
                        Divider()
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.05))
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .frame(width: 320)

            // 操作提示
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 12, height: 12)
                    Text("已禁止")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("将鼠标悬停在应用上查看操作按钮")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 8)
    }

    /**
     * 模拟应用行视图
     * 复制AppLine的交互效果和视觉样式
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
            if hoveredIndex == index {
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
                } else if hoveredIndex == index {
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
                hoveredIndex = hovering ? index : nil
            }
        }
        .frame(height: 50)
    }
}

#Preview {
    NetworkFilterDiagramView()
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
}
