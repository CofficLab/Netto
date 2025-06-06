import Foundation
import MagicCore
import OSLog
import StoreKit
import SwiftData
import SwiftUI

@MainActor
class PluginProvider: ObservableObject, SuperLog, SuperThread {
    static let shared = PluginProvider()

    private init() {}

    let emoji = "🧩"

    func getPlugins() -> some View {
        HStack(spacing: 0) {
            TileSwitcher()
            Spacer()
            TileFilter()
            Spacer()
            TileMore()
        }
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(width: 800)
    .frame(height: 800)
}
