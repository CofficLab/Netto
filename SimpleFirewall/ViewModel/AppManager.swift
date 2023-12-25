import Foundation
import SwiftUI

class AppManager: ObservableObject {
    @Published var events: [FirewallEvent] = []
    
    func appendEvent(_ e: FirewallEvent) {
        self.events.append(e)
        
        if self.events.count > 10 {
            self.events.removeFirst()
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
