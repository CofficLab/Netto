import MagicCore
import MagicUI
import ProviderFirewall
import SwiftUI

struct BtnInstallFilter: View, SuperLog {
    @Environment(\.firewallProvider) private var service: FirewallProviding?

    private var width: CGFloat = 150

    init(width: CGFloat = 150) {
        self.width = width
    }

    var body: some View {
        MagicButton.simple(icon: "puzzlepiece.extension", size: .auto, action: {
            guard let service else { return }
            Task {
                try? await service.installFilter()
            }
        })
        .magicTitle("安装过滤器")
        .magicShape(.roundedRectangle)
        .frame(width: width)
        .frame(height: 50)
    }
}

#Preview {
    RootView(environment: .preview()) {
        VStack {
            BtnInstallExtension()
            BtnInstallExtension(width: 50)
        }
    }
    .frame(height: 800)
    .frame(width: 500)
}

#Preview("APP") {
    RootView(environment: .preview()) {
        ContentView()
    }
}
