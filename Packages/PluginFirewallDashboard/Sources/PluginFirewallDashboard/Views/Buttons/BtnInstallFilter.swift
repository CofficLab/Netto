import LumiUI
import ProviderViewEnvironment
import ProviderFirewall
import SwiftUI

public struct BtnInstallFilter: View {
    @Environment(\.firewallProvider) private var service: FirewallProviding?

    private var width: CGFloat = 150

    public init(width: CGFloat = 150) {
        self.width = width
    }

    public var body: some View {
        AppButton("安装过滤器", systemImage: "puzzlepiece.extension", style: .primary, fillsWidth: true, action: {
            guard let service else { return }
            Task {
                try? await service.installFilter()
            }
        })
        .frame(width: width)
        .frame(height: 50)
    }
}

#Preview {
    BtnInstallFilter()
        .dashboardPreviewRoot()
}
