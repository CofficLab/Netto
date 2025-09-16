import SwiftUI

actor DataFolderButtonPlugin: SuperPlugin {
    nonisolated let label: String = "DataFolderButton"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        return []
    }

    @MainActor
    func addSettingsButtons() -> [(id: String, view: AnyView)] {
        return [
            (id: "open-data-folder", view: AnyView(BtnOpenDataFolder()))
        ]
    }
}

@objc(DataFolderButtonRegistrant)
class DataFolderButtonRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { await PluginRegistry.shared.register(id: "DataFolderButton", order: 35) { DataFolderButtonPlugin() } }
    }
}

#Preview("Data Folder Button Plugin") {
    ContentView()
        .inRootView()
        .frame(height: 600)
}


