import SwiftUI

@main
struct TravelModeApp: App {
    var body: some Scene {
        WindowGroup {
            RootView {
                ContentView()
            }
        }
        .commands(content: {
            DebugCommands()
        })
    }
}
