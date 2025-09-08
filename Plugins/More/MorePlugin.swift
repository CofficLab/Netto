import SwiftUI

@objc(MoreRegistrant)
class MoreRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { await PluginRegistry.shared.register(id: "More", order: 30) { MorePlugin() } }
    }
}

actor MorePlugin: SuperPlugin {
    nonisolated let label: String = "More"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        [
            (id: label, view: AnyView(TileMore()))
        ]
    }
}


#Preview("APP") {
    ContentView().inRootView()
        .frame(height: 600)
}
