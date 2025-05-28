import Foundation
import SwiftUI

class AppManager: ObservableObject {
    static let shared = AppManager()
    private init() {}
    
    @Published var status: FilterStatus = .indeterminate
    @Published var events: [FirewallEvent] = []
    @Published var logVisible: Bool = false
    @Published var dbVisible: Bool = false
    @Published var displayType: DisplayType = .All
    
    func appendEvent(_ e: FirewallEvent) {
        self.events.append(e)
        
        if self.events.count > 100 {
            self.events.removeFirst()
        }
    }
    
    func start() {
        self.status = .running
    }
    
    func stop() {
        self.status = .stopped
    }
    
    func setFilterStatus(_ status: FilterStatus) {
        self.status = status
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
