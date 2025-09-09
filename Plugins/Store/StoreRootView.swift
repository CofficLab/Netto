import OSLog
import SwiftUI
import MagicCore

/// Store 插件的 RootView
/// 用于挂载 Store 相关的环境变量和执行初始化操作
struct StoreRootView<Content: View>: View, SuperLog {
    nonisolated static var emoji: String {"🏪"}
    
    private let content: Content
    @StateObject private var storeProvider = StoreProvider()
    @State private var isInitialized = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .environmentObject(storeProvider)
            .task {
                await initializeStore()
            }
            .onDisappear {
                cleanupStore()
            }
    }
}

// MARK: - Action

extension StoreRootView {
    /// 初始化 Store 相关服务
    private func initializeStore() async {
        guard !isInitialized else { return }

        os_log("\(self.t)🚀 初始化 Store 服务")

        // 这里可以执行 Store 插件特有的初始化操作
        

            do {
                let groups = try await StoreService.requestProducts(productIds: StoreService.loadProductIdToEmojiData().keys)

                self.storeProvider.setCars(groups.cars)
//                self.storeProvider.setSubscriptions(groups.subscriptions)
//                self.storeProvider.setNonRenewables(groups.nonRenewables)
//                self.storeProvider.setFuel(groups.fuel)
            } catch let error {
                os_log(.error, "\(self.t)❌ 请求 App Store 获取产品列表出错 -> \(error.localizedDescription)")
            }
        

        isInitialized = true
        os_log("\(self.t)✅ 服务初始化完成")
    }

    /// 清理 Store 相关资源
    private func cleanupStore() {
        os_log("\(self.t)📴 清理 Store 资源")

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
