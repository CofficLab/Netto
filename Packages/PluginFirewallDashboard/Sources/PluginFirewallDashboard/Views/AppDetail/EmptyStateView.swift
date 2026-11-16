import LumiUI
import SwiftUI

/**
 * 空状态视图
 *
 * 用于在数据为空时显示提示信息，统一走 LumiUI `AppEmptyState`。
 */
struct EmptyStateView: View {
    /// 图标名称
    let iconName: String
    /// 标题文本
    let title: String
    /// 描述文本
    let description: String?

    init(
        iconName: String = "doc.text.magnifyingglass",
        title: String = "暂无数据",
        description: String? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.description = description
    }

    var body: some View {
        AppEmptyState(icon: iconName, title: title, description: description)
            .frame(maxWidth: .infinity)
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
