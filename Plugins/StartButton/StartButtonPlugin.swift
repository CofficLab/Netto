import SwiftUI

/// 开始按钮插件
actor StartButtonPlugin: SuperPlugin {
    nonisolated let label: String = "StartButton"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        return []
    }
}

@objc(StartButtonRegistrant)
class StartButtonRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { await PluginRegistry.shared.register(id: "StartButton", order: 10) { StartButtonPlugin() } }
    }
}

#Preview("Start Button Plugin") {
    ContentView()
        .inRootView()
        .frame(height: 600)
}
