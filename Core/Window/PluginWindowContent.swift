import SwiftUI
import OSLog

/// 插件窗口内容协议
@MainActor
public protocol PluginWindowContent {
    /// 窗口标题
    var windowTitle: String { get }
    
    /// 窗口内容视图
    @ViewBuilder func windowView() -> AnyView
}

/// 插件窗口管理器
@MainActor
public class PluginWindowManager: ObservableObject {
    static let shared = PluginWindowManager()
    
    @Published public var currentContent: (any PluginWindowContent)?
    @Published public var isWindowVisible = false
    
    private init() {}
    
    /// 显示插件窗口内容
    public func showWindow(with content: any PluginWindowContent) {
        currentContent = content
        isWindowVisible = true
    }
    
    /// 隐藏窗口
    public func hideWindow() {
        isWindowVisible = false
        currentContent = nil
    }
}

/// 窗口通知扩展
extension Notification.Name {
    /// 显示插件窗口的通知
    static let showPluginWindow = Notification.Name("showPluginWindow")
    
    /// 隐藏插件窗口的通知
    static let hidePluginWindow = Notification.Name("hidePluginWindow")
}
