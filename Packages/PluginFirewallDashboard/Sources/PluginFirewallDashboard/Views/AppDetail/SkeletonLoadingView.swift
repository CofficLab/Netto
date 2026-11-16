import LumiUI
import SwiftUI

/**
 * 骨架屏加载视图
 *
 * 用于在数据加载时显示占位符，占位条样式统一走 LumiUI `AppSkeleton`。
 */
struct SkeletonLoadingView: View {
    /// 骨架屏行数，默认5行
    let rowCount: Int

    init(rowCount: Int = 5) {
        self.rowCount = rowCount
    }

    var body: some View {
        VStack(spacing: AppUI.Spacing.sm) {
            ForEach(0 ..< rowCount, id: \.self) { _ in
                HStack(spacing: AppUI.Spacing.md) {
                    AppSkeletonBlock(width: 150, height: 12)
                    AppSkeletonBlock(width: 120, height: 12)
                    AppSkeletonBlock(width: 60, height: 12)
                    AppSkeletonBlock(width: 60, height: 12)
                    AppSkeletonBlock(width: 60, height: 12)
                }
            }
        }
        .padding(.vertical, AppUI.Spacing.sm)
    }
}

// MARK: - Preview

#Preview("Skeleton") {
    SkeletonLoadingView()
        .frame(width: 600, height: 200)
}

#Preview("大屏幕") {
    ContentView()
        .dashboardPreviewRoot()
        .frame(width: 600, height: 1000)
}

#Preview("小屏幕") {
    ContentView()
        .dashboardPreviewRoot()
        .frame(width: 500, height: 800)
}
