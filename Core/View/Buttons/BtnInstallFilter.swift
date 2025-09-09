import MagicCore
import MagicUI
import SwiftUI

struct BtnInstallFilter: View, SuperLog {
    @EnvironmentObject private var service: FirewallService

    private var width: CGFloat = 150

    init(width: CGFloat = 150) {
        self.width = width
    }

    var body: some View {
        MagicButton.simple(icon: "puzzlepiece.extension", size: .auto, action: {
            Task {
                try? await service.installFilter(reason: self.className)
            }
        })
        .magicTitle("安装过滤器")
        .magicShape(.roundedRectangle)
        .frame(width: width)
        .frame(height: 50)
    }
}

#Preview {
    RootView {
        VStack {
            BtnInstallExtension()
            BtnInstallExtension(width: 50)
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
