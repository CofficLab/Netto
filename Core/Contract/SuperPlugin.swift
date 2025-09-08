import OSLog
import SwiftUI

protocol SuperPlugin: Actor {
    nonisolated var label: String { get }

    @MainActor func addToolBarButtons() -> [(id: String, view: AnyView)]
}

extension SuperPlugin {
    nonisolated var id: String { self.label }
}
