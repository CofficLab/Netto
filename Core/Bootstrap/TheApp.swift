import SwiftUI

@main
struct TheApp: App {
    var body: some Scene {
        MenuBarExtra("TravelMode", systemImage: "network") {
            RootView {
                ContentView()
            }
            .frame(minHeight: 500)
            .frame(minWidth: 300)
        }.menuBarExtraStyle(.window)
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
