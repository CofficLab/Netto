import SwiftUI
import MagicKit

struct StatusBar: View {
    @EnvironmentObject var p: PluginProvider

    var body: some View {
        p.getPlugins()
        .padding(.trailing, 10)
        .labelStyle(.iconOnly)
        .background(BackgroundView.type2.opacity(0.2))
    }
}

#Preview("StatusBar") {
    RootView {
        StatusBar()
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(width: 1000)
    .frame(height: 800)
}
