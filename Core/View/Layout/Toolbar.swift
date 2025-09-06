import MagicCore
import SwiftUI

struct Toolbar: View, SuperLog {
    @EnvironmentObject private var app: UIProvider
    @EnvironmentObject private var s: ServiceProvider

    var body: some View {
        HStack {
            ZStack {
                switch s.getFirewallServiceStatus() {
                case .stopped:
                    BtnStart(asToolbarItem: true).labelStyle(.iconOnly)
                case .indeterminate:
                    Button("Status Unknown") {}
                case .running:
                    BtnStop(asToolbarItem: true).labelStyle(.iconOnly)
                case .notInstalled, .disabled, .extensionNotReady, .needApproval, .waitingForApproval, .error:
                    EmptyView()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 500)
}
