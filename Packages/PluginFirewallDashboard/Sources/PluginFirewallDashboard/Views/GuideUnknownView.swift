import LumiUI
import SwiftUI

/// 未知状态引导。
struct UnknownView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "questionmark.circle",
            title: "当前状态未知"
        ) {
            Text("暂时无法读取防火墙状态，请稍后重试。")
                .font(.appBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    DashboardPreviewHost {
        UnknownView()
    }
    .frame(height: 500)
}

#Preview {
    DashboardPreviewHost {
        ContentView()
    }
    .frame(height: 800)
}
