import Combine
import Foundation
import MagicCore
import OSLog
import SwiftUI

@MainActor
class ServiceProvider: ObservableObject, SuperLog {
    nonisolated static let emoji = "💾"
    
    let versionService: VersionService
    
    init(versionService: VersionService) {
        self.versionService = versionService
    }
}

// MARK: - Preview

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 600)
}
