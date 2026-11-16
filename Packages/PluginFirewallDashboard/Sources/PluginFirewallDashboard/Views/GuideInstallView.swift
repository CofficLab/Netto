import LumiUI
import ProviderFirewall
import ProviderViewEnvironment
import SwiftUI

/// 安装系统扩展引导。
struct InstallView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "gearshape.arrow.triangle.2.circlepath",
            title: "需要安装系统扩展",
            iconColor: .accentColor
        ) {
            DashboardInstallExtensionButton()
        }
    }
}

#Preview {
    DashboardPreviewHost {
        InstallView()
    }
    .frame(height: 500)
    .frame(width: 500)
}

#Preview("APP") {
    DashboardPreviewHost {
        ContentView()
    }
    .frame(height: 800)
}
