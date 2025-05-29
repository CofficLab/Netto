import SwiftUI
import MagicCore

struct GuideView: View {
    @EnvironmentObject private var app: UIProvider

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
            MagicBackground.forest.opacity(0.3)

            VStack(spacing: 0) {
                switch app.status {
                case .disabled, .stopped:
                    StopView()
                case .indeterminate:
                    UnknownView()
                case .running:
                    RunningView()
                case .notInstalled:
                    InstallView()
                case .needApproval:
                    ApprovalView()
                case .extensionNotReady:
                    ExtensionNotReady()
                case .waitingForApproval:
                    Text("Click \"Allow\" to install extension")
                        .font(.title)
                    Image("Ask")
                case let .error(error):
                    VStack {
                        InstallView()

                        Text("Error: \(error.localizedDescription)")
                            .font(.callout)
                            .padding(20)
                            .background(MagicBackground.cherry)
                    }
                }
            }
            .background(.background)
            .cornerRadius(16)
            .padding(20)
            .shadow(color: Color.blue.opacity(0.2), radius: 10, x: 0, y: 2)
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
