import SwiftUI

/// 退出按钮插件
actor QuitButtonPlugin: SuperPlugin {
    nonisolated let label: String = "QuitButton"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        return []
    }
    
    @MainActor
    func addSettingsButtons() -> [(id: String, view: AnyView)] {
        return [
            (id: "quit", view: AnyView(BtnQuit()))
        ]
    }
}

@objc(QuitButtonRegistrant)
class QuitButtonRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { await PluginRegistry.shared.register(id: "QuitButton", order: 60) { QuitButtonPlugin() } }
    }
}

#Preview("Quit Button Plugin") {
    ContentView()
        .inRootView()
        .frame(height: 600)
}
