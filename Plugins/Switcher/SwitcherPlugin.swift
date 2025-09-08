import SwiftUI

actor SwitcherPlugin: SuperPlugin {
    nonisolated let label: String = "Switcher"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        [
            (id: label, view: AnyView(TileSwitcher()))
        ]
    }
}


@objc(SwitcherRegistrant)
class SwitcherRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { await PluginRegistry.shared.register(id: "Switcher", order: 10) { SwitcherPlugin() } }
    }
}

#Preview("APP") {
    ContentView().inRootView()
        .frame(height: 600)
}
