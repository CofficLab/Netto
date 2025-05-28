import MagicCore
import SwiftUI

struct Topbar: View {
    @EnvironmentObject var p: PluginProvider

    var body: some View {
        HStack {
            p.getPlugins()
//                .labelStyle(.iconOnly)
        }
        .frame(height: 30)
        .background(BackgroundView.type2.opacity(0.2))
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
