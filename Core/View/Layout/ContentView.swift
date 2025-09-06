import MagicCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var ui: UIProvider

    var body: some View {
        VStack(spacing: 0) {
            Topbar()

            AppList()
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigation, content: {
                Picker("Type", selection: $ui.displayType) {
                    Text("All").tag(DisplayType.All)
                    Text("Allowed").tag(DisplayType.Allowed)
                    Text("Rejected").tag(DisplayType.Rejected)
                }
            })
            ToolbarItem {
                Toolbar()
            }
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 800)
}
