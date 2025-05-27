import SwiftUI

@main
struct TheApp: App {
    @StateObject private var app = AppManager()
    @StateObject private var event = EventManager()
    @StateObject private var channel = ChannelProvider()
    @StateObject private var m = MessageProvider()
    @StateObject private var p = PluginProvider()
    
    var body: some Scene {
        MenuBarExtra("TravelMode", systemImage: "network") {
            RootView {
                ContentView()
            }
            .environmentObject(app)
            .environmentObject(event)
            .environmentObject(channel)
            .environmentObject(m)
            .environmentObject(p)
        }.menuBarExtraStyle(.window)
    }
}
