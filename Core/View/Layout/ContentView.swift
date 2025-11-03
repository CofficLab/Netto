import MagicCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var ui: UIProvider

    var body: some View {
        VStack(spacing: 0) {
            TopBar()

            AppList()
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("")
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 800)
}
