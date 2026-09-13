import SwiftUI

/**
 * 空状态视图
 *
 * 用于在数据为空时显示提示信息，支持自定义图标、标题和描述
 */
struct EmptyStateView: View {
    /// 图标名称
    let iconName: String
    /// 标题文本
    let title: String
    /// 描述文本
    let description: String?
    /// 图标大小
    let iconSize: CGFloat
    /// 图标颜色
    let iconColor: Color

    init(
        iconName: String = "doc.text.magnifyingglass",
        title: String = "暂无数据",
        description: String? = nil,
        iconSize: CGFloat = 32,
        iconColor: Color = .secondary
    ) {
        self.iconName = iconName
        self.title = title
        self.description = description
        self.iconSize = iconSize
        self.iconColor = iconColor
    }

    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: iconSize))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.body)
                    .foregroundColor(.secondary)

                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Preview

#if os(macOS)
    #Preview("Empty - Large") {
        EmptyStateView()
            .frame(width: 600, height: 200)
    }

    #Preview("Empty - Small") {
        EmptyStateView(
            title: "暂无事件数据",
            description: "当前筛选条件下没有找到相关事件"
        )
        .frame(width: 400, height: 150)
    }
#endif

#if os(iOS)
    #Preview("Empty - iPhone") {
        EmptyStateView()
            .frame(width: 350, height: 200)
    }
#endif
