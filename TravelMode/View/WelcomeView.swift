import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var app: AppManager

    var body: some View {
        ZStack {
            AppListSample()
            
            Color.black.opacity(0.4)

            VStack(spacing: 0) {
                switch app.status {
                case .stopped:
                    Text("已停止监控").font(.title)
                case .indeterminate:
                    Text("状态未知").font(.title)
                case .running:
                    Text("正在监控").font(.title)
                    Text("联网的 APP 将会出现在这里").font(.title)
                case .notInstalled, .needApproval:
                    InstallView()
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
            .padding(20)
            .background(BackgroundView.type2A)
            .cornerRadius(16)
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
