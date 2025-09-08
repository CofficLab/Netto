import SwiftUI

actor MorePlugin: SuperPlugin {
    nonisolated let label: String = "More"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] {
        [
            (id: label, view: AnyView(TileMore()))
        ]
    }
}


