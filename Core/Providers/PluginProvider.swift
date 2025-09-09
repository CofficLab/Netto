import Foundation
import MagicCore
import OSLog
import StoreKit
import SwiftData
import SwiftUI

@MainActor
class PluginProvider: ObservableObject, SuperLog, SuperThread {
    let emoji = "🧩"
    @Published private var toolbarButtons: [(id: String, view: AnyView)] = []
    @Published private var pluginRootViews: [(id: String, rootViewProvider: (AnyView) -> AnyView)] = []
    @Published private var settingsButtons: [(id: String, view: AnyView)] = []

    init(autoDiscover: Bool = true) {
        if autoDiscover {
            autoRegisterPlugins()
            Task { [weak self] in
                guard let self else { return }
                let plugins = await PluginRegistry.shared.buildAll()
                let buttons: [(id: String, view: AnyView)] = plugins.flatMap { plugin in
                    plugin.addToolBarButtons()
                }
                let rootViews: [(id: String, rootViewProvider: (AnyView) -> AnyView)] = plugins.compactMap { plugin in
                    // 创建一个闭包来包装插件的 RootView 提供者
                    return (id: plugin.id, rootViewProvider: { content in
                        return plugin.provideRootView { content } ?? content
                    })
                }
                let settingsButtons: [(id: String, view: AnyView)] = plugins.flatMap { plugin in
                    plugin.addSettingsButtons()
                }
                self.toolbarButtons = buttons
                self.pluginRootViews = rootViews
                self.settingsButtons = settingsButtons
            }
        }
    }

    func getToolbarButtons() -> some View {
        return HStack(spacing: 0) {
            ForEach(Array(self.toolbarButtons.enumerated()), id: \.element.id) { index, button in
                button.view
                if index < self.toolbarButtons.count - 1 {
                    Spacer()
                }
            }
        }
    }
    
    /// 将内容视图包裹在所有插件的 RootView 中
    func wrapContent<Content: View>(_ content: Content) -> AnyView {
        var wrappedContent: AnyView = AnyView(content)
        
        // 按顺序应用所有插件的 RootView
        for rootViewProvider in pluginRootViews {
            wrappedContent = rootViewProvider.rootViewProvider(wrappedContent)
        }
        
        return wrappedContent
    }
    
    /// 获取指定插件的 RootView 包装器
    func getPluginRootViewWrapper(for pluginId: String) -> ((AnyView) -> AnyView)? {
        return pluginRootViews.first { $0.id == pluginId }?.rootViewProvider
    }
    
    /// 获取所有设置按钮
    func getSettingsButtons() -> some View {
        return VStack(spacing: 8) {
            ForEach(Array(self.settingsButtons.enumerated()), id: \.element.id) { index, button in
                button.view
            }
        }
    }
    
    /// 获取指定设置按钮
    func getSettingsButton(for buttonId: String) -> AnyView? {
        return settingsButtons.first { $0.id == buttonId }?.view
    }
    
    /// 清理资源，释放内存
    func cleanup() {
        // PluginProvider 目前没有需要清理的状态
        // 如果将来添加了状态，可以在这里清理
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(width: 800)
    .frame(height: 800)
}
