import LumiUI
import SwiftUI

/**
 * 分页控制视图
 *
 * 提供统一的分页控制功能，包括上一页、下一页按钮和页码显示
 */
struct PaginationView: View {
    /// 当前页码（从0开始）
    @Binding var currentPage: Int
    /// 总页数
    let totalPages: Int
    /// 总数据量
    let totalCount: Int
    /// 每页显示数量
    let pageSize: Int
    /// 是否正在加载
    let isLoading: Bool
    /// 上一页按钮点击回调
    let onPreviousPage: () -> Void
    /// 下一页按钮点击回调
    let onNextPage: () -> Void

    @LumiTheme private var theme

    init(
        currentPage: Binding<Int>,
        totalPages: Int,
        totalCount: Int,
        pageSize: Int,
        isLoading: Bool = false,
        onPreviousPage: @escaping () -> Void,
        onNextPage: @escaping () -> Void
    ) {
        self._currentPage = currentPage
        self.totalPages = totalPages
        self.totalCount = totalCount
        self.pageSize = pageSize
        self.isLoading = isLoading
        self.onPreviousPage = onPreviousPage
        self.onNextPage = onNextPage
    }

    var body: some View {
        HStack(spacing: AppUI.Spacing.md) {
            AppButton(systemImage: "chevron.left", style: .ghost, size: .small) {
                guard currentPage > 0 else { return }
                currentPage -= 1
                onPreviousPage()
            }
            .disabled(currentPage <= 0 || isLoading)

            Spacer(minLength: 0)

            VStack(spacing: 2) {
                Text("第 \(currentPage + 1) 页，共 \(totalPages) 页")
                    .font(.appCaption)
                    .foregroundStyle(theme.textSecondary)

                Text("共 \(totalCount) 条事件")
                    .font(.appMicro)
                    .foregroundStyle(theme.textTertiary)
            }

            Spacer(minLength: 0)

            AppButton(systemImage: "chevron.right", style: .ghost, size: .small) {
                guard currentPage < totalPages - 1 else { return }
                currentPage += 1
                onNextPage()
            }
            .disabled(currentPage >= totalPages - 1 || isLoading)
        }
        .padding(.vertical, AppUI.Spacing.sm)
    }
}

// MARK: - Preview
#if os(macOS)
#Preview("Pagination - Large") {
    VStack {
        PaginationView(
            currentPage: .constant(0),
            totalPages: 5,
            totalCount: 100,
            pageSize: 20,
            isLoading: false,
            onPreviousPage: {},
            onNextPage: {}
        )

        PaginationView(
            currentPage: .constant(2),
            totalPages: 5,
            totalCount: 100,
            pageSize: 20,
            isLoading: true,
            onPreviousPage: {},
            onNextPage: {}
        )
    }
    .frame(width: 600, height: 200)
}

#Preview("Pagination - Small") {
    PaginationView(
        currentPage: .constant(1),
        totalPages: 3,
        totalCount: 60,
        pageSize: 20,
        isLoading: false,
        onPreviousPage: {},
        onNextPage: {}
    )
    .frame(width: 400, height: 100)
}
#endif

#if os(iOS)
#Preview("Pagination - iPhone") {
    PaginationView(
        currentPage: .constant(0),
        totalPages: 4,
        totalCount: 80,
        pageSize: 20,
        isLoading: false,
        onPreviousPage: {},
        onNextPage: {}
    )
    .frame(width: 350, height: 100)
}
#endif
