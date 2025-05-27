import MagicCore
import SwiftUI

struct BtnInstall: View {
    @EnvironmentObject private var channel: ChannelProvider

    private var width: CGFloat = 150

    init(width: CGFloat = 150) {
        self.width = width
    }

    var body: some View {
        MagicButton(icon: "puzzlepiece.extension", size: .auto, action: {
            channel.installFilter()
        })
        .magicTitle("安装系统扩展")
        .magicShape(.roundedRectangle)
        .frame(width: width)
        .frame(height: 50)
    }
}

#Preview {
    RootView {
        VStack {
            BtnInstall()
            BtnInstall(width: 50)
        }
    }
    .frame(height: 800)
    .frame(width: 500)
}

#Preview {
    RootView {
        ContentView()
    }
}
