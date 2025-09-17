import SwiftUI
import MagicCore
import MagicUI

actor InstallExtensionButtonPlugin: SuperPlugin {
    nonisolated let label: String = "InstallExtensionButton"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] { [] }

    @MainActor
    func addSettingsButtons() -> [(id: String, view: AnyView)] {
        [ (id: "install-extension", view: AnyView(BtnInstallExtension())) ]
    }
}

@objc(InstallExtensionButtonRegistrant)
class InstallExtensionButtonRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { await PluginRegistry.shared.register(id: "InstallExtensionButton", order: 40) { InstallExtensionButtonPlugin() } }
    }
}

// MARK: - Preview

#Preview("App - Large") {
    ContentView()
        .inRootView()
        .frame(width: 600, height: 1000)
}

#Preview("App - Small") {
    ContentView()
        .inRootView()
        .frame(width: 600, height: 600)
}
