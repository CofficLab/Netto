import MagicCore
import SwiftUI

struct ExtensionNotReady: View {
    var body: some View {
        Popview(
            iconName: "exclamationmark.shield",
            title: "需要配置系统扩展"
        ) {
            VStack(spacing: 24) {
                BtnSetting()
//                BtnInstall()
            }
        }
    }
}

#Preview {
    RootView {
        ExtensionNotReady()
    }
    .frame(height: 500)
}

#Preview("App") {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
