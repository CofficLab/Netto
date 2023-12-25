import Foundation
import SwiftUI

class AppManager: ObservableObject {
    @Published var status: FilterStatus = .indeterminate
    @Published var events: [FirewallEvent] = []
    
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
