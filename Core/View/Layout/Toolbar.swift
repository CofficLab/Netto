import MagicCore
import SwiftUI

struct Toolbar: View, SuperLog {
    @EnvironmentObject private var app: UIProvider
    @EnvironmentObject private var firewall: FirewallService

    var body: some View {
        HStack {
            ZStack {
                switch firewall.status {
                case .stopped:
                    BtnStart(asToolbarItem: true).labelStyle(.iconOnly)
                case .indeterminate:
                    Button("Status Unknown") {}
                case .running:
                    BtnStop(asToolbarItem: true).labelStyle(.iconOnly)
                case .notInstalled,
                     .disabled,
                     .extensionNotReady,
                     .needApproval,
                     .notInApplicationsFolder,
                     .waitingForApproval,
                     .error:
                    EmptyView()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
        .inRootView()
        .frame(height: 500)
}
