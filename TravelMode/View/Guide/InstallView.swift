import SwiftUI

struct InstallView: View {
    var body: some View {
        Popview(
            iconName: "gearshape.arrow.triangle.2.circlepath",
            title: "需要安装系统扩展",
            iconColor: .blue
        ) {
            BtnInstall()
                .controlSize(.extraLarge)
        }
    }
}

#Preview {
    RootView {
        InstallView()
    }
    .frame(height: 800)
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
