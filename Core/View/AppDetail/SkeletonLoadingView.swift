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
        HStack {
            Spacer()
            VStack(spacing: 8) {
                ForEach(0 ..< rowCount, id: \.self) { _ in
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
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Skeleton") {
    SkeletonLoadingView()
        .frame(width: 600, height: 200)
}

#Preview("大屏幕") {
    ContentView()
        .inRootView()
        .frame(width: 600, height: 1000)
}

#Preview("小屏幕") {
    ContentView()
        .inRootView()
        .frame(width: 500, height: 800)
}
