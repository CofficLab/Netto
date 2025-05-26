import SwiftUI

@main
struct TravelModeApp: App {
    @StateObject private var app = AppManager()
    @StateObject private var event = EventManager()
    @StateObject private var channel = ChannelProvider()
    @StateObject private var m = MessageProvider()
    @StateObject private var p = PluginProvider()
    
    var body: some Scene {
//        MenuBarExtra("TravelMode", systemImage: "network") {
//            Button("Show Window") {
//                NSApplication.shared.activate(ignoringOtherApps: true)
//            }
//            .keyboardShortcut("w")
//            
//            Divider()
//            
//            Button("Quit") {
//                NSApplication.shared.terminate(nil)
//            }
//            .keyboardShortcut("q")
//        }
        
        WindowGroup {
            RootView {
                ContentView()
            }
            .environmentObject(app)
            .environmentObject(event)
            .environmentObject(channel)
            .environmentObject(m)
            .environmentObject(p)
        }
        .commands(content: {
            DebugCommands()
        })
    }
}
