import SwiftUI

actor DBPlugin: SuperPlugin {
    nonisolated let label: String = "DBPlugin"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        return []
    }

    @MainActor
    func addSettingsButtons() -> [(id: String, view: AnyView)] {
        #if DEBUG
        return [
            (id: "db", view: AnyView(DBSheetButton()))
        ]
        #else
        return []
        #endif
    }
}

@objc(DBPluginRegistrant)
class DBPluginRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { await PluginRegistry.shared.register(id: "DBPlugin", order: 20) { DBPlugin() } }
    }
}

#Preview("DB Plugin") {
    ContentView()
        .inRootView()
        .frame(height: 600)
}


