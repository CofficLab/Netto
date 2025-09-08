import SwiftUI

actor StorePlugin: SuperPlugin {
    nonisolated let label: String = "Store"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        [
            (id: label, view: AnyView(StoreSettingEntry()
                .environmentObject(StoreProvider())))
        ]
    }
}

@objc(StoreRegistrant)
class StoreRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { await PluginRegistry.shared.register(id: "Store", order: 40) { StorePlugin() } }
    }
}

#Preview("APP") {
    ContentView().inRootView()
        .frame(height: 600)
}


