import MagicCore
import ProviderFirewall
import ProviderViewEnvironment
import SwiftUI
import MagicUI

public struct BtnInstallExtension: View {
    @Environment(\.firewallProvider) private var service: FirewallProviding?

    private var width: CGFloat = 150

    public init(width: CGFloat = 150) {
        self.width = width
    }

    public var body: some View {
        MagicButton.simple(icon: "puzzlepiece.extension", size: .auto, action: {
            guard let service else { return }
            Task {
                await service.installSystemExtension()
            }
        })
        .magicTitle("安装系统扩展")
        .magicShape(.roundedRectangle)
        .frame(width: width)
        .frame(height: 50)
    }
}
