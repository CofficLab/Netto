import MagicCore
import SwiftUI

struct BtnInstall: View {
    @EnvironmentObject private var channel: ChannelProvider

    var body: some View {
        MagicButton(icon: "puzzlepiece.extension", size: .auto, action: {
            channel.installFilter()
        })
        .magicTitle("安装系统扩展")
        .magicShape(.roundedRectangle)
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
