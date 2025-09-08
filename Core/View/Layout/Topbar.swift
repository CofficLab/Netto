import MagicCore
import SwiftUI
import MagicBackground

struct Topbar: View {
    @EnvironmentObject var p: PluginProvider

    var body: some View {
        HStack {
            p.getPlugins()
        }
        .frame(height: 30)
        .background(MagicBackground.colorTeal.opacity(0.2))
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
