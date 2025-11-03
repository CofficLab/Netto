import SwiftUI

actor FilterPlugin: SuperPlugin {
    nonisolated let label: String = "Filter"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        [
            (id: label, view: AnyView(TileFilter()))
        ]
    }
    
    @MainActor
    func getTopBarPosition() -> TopBarPosition {
        return .center
    }
}

@objc(FilterRegistrant)
class FilterRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { await PluginRegistry.shared.register(id: "Filter", order: 20) { FilterPlugin() } }
    }
}

#Preview("APP") {
    ContentView().inRootView()
        .frame(height: 600)
}
