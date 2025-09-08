import Combine
import Foundation
import MagicCore
import MediaPlayer
import OSLog
import SwiftUI

class AppProvider: NSObject, ObservableObject, SuperLog, SuperThread {
    nonisolated static let emoji = "🐮"

    @Published var showSheet: Bool = true
    @Published var isImporting: Bool = false
    @Published var isDropping: Bool = false
    @Published var rightAlbumVisible = false
}

#Preview("Small Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 500)
    .frame(height: 600)
}

#Preview("Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 800)
    .frame(height: 1200)
}
