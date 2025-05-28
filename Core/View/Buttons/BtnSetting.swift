import MagicCore
import SwiftUI

struct BtnSetting: View {
    var body: some View {
        MagicButton(action: {
            if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?extensionPointIdentifier=com.apple.system_extension.network_extension.extension-point") {
                NSWorkspace.shared.open(url)
            }
        })
        .magicIcon(.iconSettings)
        .magicTitle("打开系统设置")
        .magicSize(.auto)
        .frame(width: 150)
        .frame(height: 50)
    }
}

#Preview {
    RootView {
        ContentView()
    }
}

#Preview {
    RootView {
        BtnInstall()
    }
    .frame(height: 800)
}
