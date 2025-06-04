import Combine
import Foundation
import MagicCore
import OSLog
import SwiftUI

@MainActor
class ServiceProvider: ObservableObject, SuperLog {
    nonisolated static let emoji = "💾"
    
    let firewallService: FirewallService
    let firewallEventService: EventService
    let versionService: VersionService
    
    init(firewallService: FirewallService, firewallEventService: EventService, versionService: VersionService) {
        self.firewallService = firewallService
        self.firewallEventService = firewallEventService
        self.versionService = versionService
    }
    
    func startFilter(reason: String) async throws {
        try await firewallService.startFilter(reason: reason)
    }
    
    func stopFilter(reason: String) async throws {
        try await firewallService.stopFilter(reason: reason)
    }
    
    func installFilter() {
        firewallService.installFilter()
    }
    
    func viewWillDisappear() {
        firewallService.viewWillDisappear()
    }
    
    func getFirewallServiceStatus() -> FilterStatus {
        firewallService.status
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 600)
}
