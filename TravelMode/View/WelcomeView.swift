import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var app: AppManager

    var body: some View {
        ZStack {
            AppListSample()
            
            Color.black.opacity(0.4)

            VStack(spacing: 0) {
                switch app.status {
                case .disabled:
                    DisabledView()
                case .stopped:
                    StopView()
                case .indeterminate:
                    UnkownView()
                case .running:
                    RunningView()
                case .notInstalled:
                    InstallView()
                case .needApproval:
                    ApprovalView()
                case .extensionNotReady:
                    ExtensionNotReady()
                case .waitingForApproval:
                    Text("点击“允许”以安装扩展").font(.title)
                    Image("Ask")
                case let .error(error):
                    VStack {
                        InstallView()

                        Text("错误: \(error.localizedDescription)")
                            .font(.callout)
                            .padding(20)
                            .background(BackgroundView.type2A.rotationEffect(.degrees(180)))
                    }
                }
            }
            .background(BackgroundView.type2A)
            .cornerRadius(16)
            .padding(20)
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
