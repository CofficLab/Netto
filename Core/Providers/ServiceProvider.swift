import Combine
import Foundation
import MagicCore
import OSLog
import SwiftUI

@MainActor
class ServiceProvider: ObservableObject, SuperLog {
    nonisolated static let emoji = "💾"
    
    static let shared = ServiceProvider()
    
    private let firewallService: FirewallService = .shared
    
    func startFilter(reason: String) async throws {
        try await firewallService.startFilter(reason: reason)
    }
    
    func stopFilter(reason: String) async throws {
        try await firewallService.stopFilter(reason: reason)
    }
    
    func viewWillDisappear() {
        firewallService.viewWillDisappear()
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 600)
}
