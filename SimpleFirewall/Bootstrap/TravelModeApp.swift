import SwiftUI

@main
struct TravelModeApp: App {
    private var app: AppManager = AppManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(app)
        }
    }
}
