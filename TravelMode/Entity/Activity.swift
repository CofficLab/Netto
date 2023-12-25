import Foundation
import AppKit
import SwiftUI

struct Activity: Identifiable {
    var id: String = UUID().uuidString
    var app: NSRunningApplication
    var events: [FirewallEvent] = []
    
    var appName: String {
        app.localizedName ?? ""
    }
    var appId: String {
        app.bundleIdentifier ?? ""
    }
    var appIcon: NSImage {
        app.icon ?? NSImage()
    }
    
    func appendEvent(_ e: FirewallEvent) -> Self {
        var cloned = self
        cloned.events.append(e)
        
        return cloned
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
