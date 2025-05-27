import MagicCore
import SwiftUI

struct StatusBar: View {
    @EnvironmentObject var p: PluginProvider
    @EnvironmentObject var app: AppManager

    var body: some View {
        HStack {
            ZStack {
                switch app.status {
                case .stopped:
                    BtnStart(asToolbarItem: true).labelStyle(.iconOnly)
                case .indeterminate:
                    EmptyView()
                case .running:
                    BtnStop(asToolbarItem: true).labelStyle(.iconOnly)
                case .notInstalled, .disabled, .extensionNotReady, .needApproval, .waitingForApproval, .error:
                    EmptyView()
                }
            }

            p.getPlugins()
                .padding(.trailing, 10)
                .labelStyle(.iconOnly)
                .background(BackgroundView.type2.opacity(0.2))
        }
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
