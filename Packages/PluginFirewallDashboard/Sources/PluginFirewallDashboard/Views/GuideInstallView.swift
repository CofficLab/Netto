import SwiftUI
import ProviderSettingsUI

struct InstallView: View {
    var body: some View {
        Popview(
            iconName: "gearshape.arrow.triangle.2.circlepath",
            title: "需要安装系统扩展",
            iconColor: .blue
        ) {
            BtnInstallExtension()
                .controlSize(.extraLarge)
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
