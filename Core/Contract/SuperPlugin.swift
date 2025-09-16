import OSLog
import SwiftUI

/// 插件在 Topbar 中的位置
enum TopbarPosition: String, CaseIterable {
    case left = "left"      // 左侧
    case center = "center"  // 中心
    case right = "right"    // 右侧
}

protocol SuperPlugin: Actor {
    nonisolated var label: String { get }

    @MainActor func addToolBarButtons() -> [(id: String, view: AnyView)]
    
    /// 插件提供的 RootView，用于挂载插件的环境变量和执行初始化操作
    /// - Parameter content: 要包裹的内容视图
    /// - Returns: 插件的 RootView，如果插件不需要提供 RootView 则返回 nil
    @MainActor func provideRootView<Content: View>(@ViewBuilder content: () -> Content) -> AnyView?
    
    /// 插件提供的设置按钮内部的按钮
    /// - Returns: 设置按钮内部的按钮列表，如果插件不提供设置按钮则返回空数组
    @MainActor func addSettingsButtons() -> [(id: String, view: AnyView)]
    
    /// 插件在 Topbar 中的位置
    /// - Returns: 插件希望在 Topbar 中显示的位置，默认为左侧
    @MainActor func getTopbarPosition() -> TopbarPosition
    
    /// 插件提供的窗口内容
    /// - Returns: 插件希望在独立窗口中显示的内容，如果插件不需要独立窗口则返回 nil
    @MainActor func provideWindowContent() -> (any PluginWindowContent)?
}

extension SuperPlugin {
    nonisolated var id: String { self.label }
    
    /// 默认实现：插件不提供 RootView
    @MainActor func provideRootView<Content: View>(@ViewBuilder content: () -> Content) -> AnyView? {
        return nil
    }
    
    /// 默认实现：插件不提供设置按钮
    @MainActor func addSettingsButtons() -> [(id: String, view: AnyView)] {
        return []
    }
    
    /// 默认实现：插件显示在左侧
    @MainActor func getTopbarPosition() -> TopbarPosition {
        return .left
    }
    
    /// 默认实现：插件不提供窗口内容
    @MainActor func provideWindowContent() -> (any PluginWindowContent)? {
        return nil
    }
}
