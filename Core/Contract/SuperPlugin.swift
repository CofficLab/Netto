import OSLog
import SwiftUI

protocol SuperPlugin: Actor {
    nonisolated var label: String { get }

    @MainActor func addToolBarButtons() -> [(id: String, view: AnyView)]
    
    /// 插件提供的 RootView，用于挂载插件的环境变量和执行初始化操作
    /// - Parameter content: 要包裹的内容视图
    /// - Returns: 插件的 RootView，如果插件不需要提供 RootView 则返回 nil
    @MainActor func provideRootView<Content: View>(@ViewBuilder content: () -> Content) -> AnyView?
}

extension SuperPlugin {
    nonisolated var id: String { self.label }
    
    /// 默认实现：插件不提供 RootView
    @MainActor func provideRootView<Content: View>(@ViewBuilder content: () -> Content) -> AnyView? {
        return nil
    }
}
