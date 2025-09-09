import SwiftUI

/// 关于按钮插件
actor AboutButtonPlugin: SuperPlugin {
    nonisolated let label: String = "AboutButton"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        return []
    }
    
    @MainActor
    func addSettingsButtons() -> [(id: String, view: AnyView)] {
        return [
            (id: "about", view: AnyView(BtnAbout()))
        ]
    }
}

@objc(AboutButtonRegistrant)
class AboutButtonRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { await PluginRegistry.shared.register(id: "AboutButton", order: 50) { AboutButtonPlugin() } }
    }
}

#Preview("About Button Plugin") {
    ContentView()
        .inRootView()
        .frame(height: 600)
}
