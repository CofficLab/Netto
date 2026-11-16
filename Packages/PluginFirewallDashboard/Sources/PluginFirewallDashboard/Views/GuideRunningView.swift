import LumiUI
import SwiftUI

/// 运行中视图：按当前筛选维度提示列表将显示什么。
struct RunningView: View {
    @EnvironmentObject var app: UIProvider

    var body: some View {
        DashboardGuidePanel(
            iconName: "inset.filled.rectangle.badge.record",
            title: "正在监控",
            iconColor: .green
        ) {
            VStack(spacing: AppUI.Spacing.sm) {
                switch app.displayType {
                case .All:
                    AppStatusBanner(kind: .info, title: "联网的 APP 将显示在这里")
                case .Allowed:
                    AppStatusBanner(kind: .info, title: "被允许联网的 APP 将显示在这里")
                case .Rejected:
                    AppStatusBanner(kind: .info, title: "被禁止联网的 APP 将显示在这里")
                    AppStatusBanner(kind: .warning, title: "当前没有出现被禁止联网的 APP")
                }
            }
        }
    }
}

#Preview {
    DashboardPreviewHost {
        RunningView()
    }
    .frame(height: 500)
}

#Preview("APP") {
    DashboardPreviewHost {
        ContentView()
    }
    .frame(height: 800)
}
