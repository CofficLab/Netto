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


