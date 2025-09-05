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
    /// 是否正在加载
    let isLoading: Bool
    /// 上一页按钮点击回调
    let onPreviousPage: () -> Void
    /// 下一页按钮点击回调
    let onNextPage: () -> Void
    
    init(
        currentPage: Binding<Int>,
        totalPages: Int,
        isLoading: Bool = false,
        onPreviousPage: @escaping () -> Void,
        onNextPage: @escaping () -> Void
    ) {
        self._currentPage = currentPage
        self.totalPages = totalPages
        self.isLoading = isLoading
        self.onPreviousPage = onPreviousPage
        self.onNextPage = onNextPage
    }
    
    var body: some View {
        HStack {
            Button(action: {
                if currentPage > 0 {
                    currentPage -= 1
                    onPreviousPage()
                }
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor((currentPage > 0 && !isLoading) ? .primary : .secondary)
            }
            .disabled(currentPage <= 0 || isLoading)

            Spacer()

            Text("第 \(currentPage + 1) 页，共 \(totalPages) 页")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button(action: {
                if currentPage < totalPages - 1 {
                    currentPage += 1
                    onNextPage()
                }
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor((currentPage < totalPages - 1 && !isLoading) ? .primary : .secondary)
            }
            .disabled(currentPage >= totalPages - 1 || isLoading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.controlBackgroundColor).opacity(0.6))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 0)
        .padding(.bottom, 8)
    }
}

// MARK: - Preview
#if os(macOS)
#Preview("Pagination - Large") {
    VStack {
        PaginationView(
            currentPage: .constant(0),
            totalPages: 5,
            isLoading: false,
            onPreviousPage: {},
            onNextPage: {}
        )
        
        PaginationView(
            currentPage: .constant(2),
            totalPages: 5,
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
        isLoading: false,
        onPreviousPage: {},
        onNextPage: {}
    )
    .frame(width: 350, height: 100)
}
#endif
