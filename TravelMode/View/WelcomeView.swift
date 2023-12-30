import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var app: AppManager

    var body: some View {
        VStack(spacing:0) {
            switch app.status {
            case .stopped:
                Text("已停止监控").font(.title)
            case .indeterminate:
                Text("状态未知").font(.title)
            case .running:
                Text("正在监控").font(.title)
                Text("联网的 APP 将会出现在这里").font(.title)
            case .notInstalled:
                ZStack {
                    AppListSample()
                    Color.black.opacity(0.65)
                    
                    VStack {
                        BtnInstall()
                        Text("安装系统扩展以继续")
                            .font(.headline)
                            .padding(.top, 20)
                    }.padding(30).background(BackgroundView.type2).cornerRadius(16)
                }
            case .needApproval:
                Text("请在系统设置中允许运行").font(.title)
                Image("NeedApproval").resizable().scaledToFit()
            case .waitingForApproval:
                Text("点击“允许”以安装扩展").font(.title)
                Image("Ask")
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
