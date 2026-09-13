import MagicCore
import MagicUI
import SwiftUI

public struct BtnSetting: View {
    public init() {}

    public var body: some View {
        MagicButton.simple(action: {
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
    BtnSetting().dashboardPreviewRoot()
}

#Preview {
    BtnInstallExtension().dashboardPreviewRoot()
}
