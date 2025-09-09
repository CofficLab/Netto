import SwiftUI

/// 指南按钮插件
actor GuideButtonPlugin: SuperPlugin {
    nonisolated let label: String = "GuideButton"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        return []
    }
    
    @MainActor
    func addSettingsButtons() -> [(id: String, view: AnyView)] {
        return [
            (id: "guide", view: AnyView(BtnGuide()))
        ]
    }
}

@objc(GuideButtonRegistrant)
class GuideButtonRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { await PluginRegistry.shared.register(id: "GuideButton", order: 40) { GuideButtonPlugin() } }
    }
}

#Preview("Guide Button Plugin") {
    ContentView()
        .inRootView()
        .frame(height: 600)
}
