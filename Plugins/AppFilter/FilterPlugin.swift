import SwiftUI

actor FilterPlugin: SuperPlugin {
    nonisolated let label: String = "Filter"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        [
            (id: label, view: AnyView(TileFilter()))
        ]
    }
}


