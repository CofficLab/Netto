import MagicCore
import OSLog
import SwiftUI

struct AppLine: View, SuperEvent {
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var ui: UIProvider

    var app: SmartApp

    init(app: SmartApp) {
        self.app = app
    }

    var body: some View {
        AppInfo(
            app: app,
            iconSize: 40,
            isCompact: false
        )
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}
