import MagicKit
import SwiftUI

struct Toolbar: View, SuperLog {
    @EnvironmentObject private var app: AppManager
    @EnvironmentObject private var channel: ChannelProvider

    private var shouldShowLogButton: Bool {
        switch app.status {
        case .stopped:
            true
        case .indeterminate:
            false
        case .running:
            true
        case .notInstalled:
            false
        case .needApproval:
            false
        case .waitingForApproval:
            false
        case .error:
            false
        case .disabled, .extensionNotReady:
            false
        }
    }

    var body: some View {
        HStack {
            if shouldShowLogButton {
                BtnToggleLog().labelStyle(.iconOnly)
            }

            ZStack {
                switch app.status {
                case .stopped:
                    BtnStart().labelStyle(.iconOnly)
                case .indeterminate:
                    Button("Status Unknown") {}
                case .running:
                    BtnStop().labelStyle(.iconOnly)
                case .notInstalled, .disabled, .extensionNotReady, .needApproval, .waitingForApproval, .error:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
