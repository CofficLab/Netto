import MagicCore
import ProviderViewEnvironment
import MagicUI
import ProviderFirewall
import SwiftUI

public struct BtnInstallFilter: View, SuperLog {
    @Environment(\.firewallProvider) private var service: FirewallProviding?

    private var width: CGFloat = 150

    public init(width: CGFloat = 150) {
        self.width = width
    }

    public var body: some View {
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
    BtnInstallFilter()
        .dashboardPreviewRoot()
}
