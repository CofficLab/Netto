import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var app: AppManager

    var body: some View {
        VStack {
            Spacer()
            switch app.status {
            case .stopped:
                Text("已停止监控").font(.title)
            case .indeterminate:
                Text("状态未知").font(.title)
            case .running:
                Text("正在监控").font(.title)
                Text("联网的 APP 将会出现在这里").font(.title)
            case .notInstalled:
                Text("点击“开始”以安装扩展").font(.title)
            case .needApproval:
                Text("请在系统设置中允许运行").font(.title)
                Image("NeedApproval").resizable().scaledToFit()
            case .waitingForApproval:
                Text("点击“允许”以安装扩展").font(.title)
                Image("Ask")
            }
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RootView {
        WelcomeView()
    }
}
