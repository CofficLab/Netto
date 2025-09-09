import SwiftUI

actor StorePlugin: SuperPlugin {
    nonisolated let label: String = "Store"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        return []
    }
    
    @MainActor
    func addSettingsButtons() -> [(id: String, view: AnyView)] {
        return [
            (id: "store", view: AnyView(StoreBtn()))
        ]
    }
    
    @MainActor
    func provideRootView<Content: View>(@ViewBuilder content: () -> Content) -> AnyView? {
        // 示例：Store 插件提供自己的 RootView 来管理 Store 相关的环境变量
        return AnyView(StoreRootView(content: content))
    }
}

@objc(StoreRegistrant)
class StoreRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { await PluginRegistry.shared.register(id: "Store", order: 40) { StorePlugin() } }
    }
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(height: 600)
}


