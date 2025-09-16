import SwiftUI

/// 停止按钮插件
actor StopButtonPlugin: SuperPlugin {
    nonisolated let label: String = "StopButton"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        return []
    }
}

@objc(StopButtonRegistrant)
class StopButtonRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { await PluginRegistry.shared.register(id: "StopButton", order: 20) { StopButtonPlugin() } }
    }
}

#Preview("Stop Button Plugin") {
    ContentView()
        .inRootView()
        .frame(height: 600)
}
