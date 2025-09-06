import MagicCore
import SwiftUI

struct BtnInstall: View {
    @EnvironmentObject private var service: FirewallService

    private var width: CGFloat = 150

    init(width: CGFloat = 150) {
        self.width = width
    }

    var body: some View {
        MagicButton.simple(icon: "puzzlepiece.extension", size: .auto, action: {
            service.installFilter()
        })
        .magicTitle("安装")
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

#Preview("APP") {
    RootView {
        ContentView()
    }
}
