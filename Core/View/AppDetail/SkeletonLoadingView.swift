import SwiftUI

/**
 * 骨架屏加载视图
 * 
 * 用于在数据加载时显示占位符，提升用户体验
 */
struct SkeletonLoadingView: View {
    /// 骨架屏行数，默认5行
    let rowCount: Int
    
    init(rowCount: Int = 5) {
        self.rowCount = rowCount
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<rowCount, id: \.self) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 150, height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 16)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
#if os(macOS)
#Preview("Skeleton - Large") {
    SkeletonLoadingView()
        .frame(width: 600, height: 200)
}

#Preview("Skeleton - Small") {
    SkeletonLoadingView(rowCount: 3)
        .frame(width: 400, height: 120)
}
#endif

#if os(iOS)
#Preview("Skeleton - iPhone") {
    SkeletonLoadingView()
        .frame(width: 350, height: 200)
}
#endif
