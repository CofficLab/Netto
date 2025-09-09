import OSLog
import SwiftUI

/// Store 插件的 RootView
/// 用于挂载 Store 相关的环境变量和执行初始化操作
struct StoreRootView<Content: View>: View {
    private let content: Content
    @StateObject private var storeProvider = StoreProvider()
    @State private var isInitialized = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .environmentObject(storeProvider)
            .onAppear {
                initializeStore()
            }
            .onDisappear {
                cleanupStore()
            }
    }
}

// MARK: - Action

extension StoreRootView {
    /// 初始化 Store 相关服务
    private func initializeStore() {
        guard !isInitialized else { return }

        os_log("🏪 StoreRootView: 初始化 Store 服务")

        // 这里可以执行 Store 插件特有的初始化操作
        // 例如：加载产品列表、检查订阅状态等

        isInitialized = true
        os_log("🏪 StoreRootView: Store 服务初始化完成")
    }

    /// 清理 Store 相关资源
    private func cleanupStore() {
        os_log("🏪 StoreRootView: 清理 Store 资源")

        // 这里可以执行 Store 插件特有的清理操作
        // 例如：取消网络请求、清理缓存等

        isInitialized = false
    }
}

// MARK: - Preview

#Preview("Buy") {
    BuySetting()
        .inRootView()
        .frame(height: 800)
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(width: 700)
        .frame(height: 800)
}
