import SwiftUI

/// 设置按钮插件
actor SettingButtonPlugin: SuperPlugin {
    nonisolated let label: String = "SettingButton"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        return []
    }
    
    @MainActor
    func addSettingsButtons() -> [(id: String, view: AnyView)] {
        return [
            (id: "setting", view: AnyView(BtnSetting()))
        ]
    }
}

@objc(SettingButtonRegistrant)
class SettingButtonRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { await PluginRegistry.shared.register(id: "SettingButton", order: 30) { SettingButtonPlugin() } }
    }
}

#Preview("Setting Button Plugin") {
    ContentView()
        .inRootView()
        .frame(height: 600)
}
