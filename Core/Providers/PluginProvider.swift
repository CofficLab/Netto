import Foundation
import MagicCore
import OSLog
import StoreKit
import SwiftData
import SwiftUI

class PluginProvider: ObservableObject, SuperLog, SuperThread {
    let emoji = "🧩"

    func getPlugins() -> some View {
        HStack(spacing: 0) {
            TileSwitcher()
            TileLog()
            Spacer()
            TileState()
            Spacer()
            TileMessage()
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
