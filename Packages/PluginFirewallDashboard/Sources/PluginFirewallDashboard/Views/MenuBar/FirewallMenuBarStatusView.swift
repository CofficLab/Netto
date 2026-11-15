import ProviderFirewall
import SwiftUI

/// 菜单栏状态项里由插件贡献的图标：防火墙状态 + 被阻止应用提示点。
struct FirewallMenuBarStatusView: View {
    let firewall: any FirewallProviding
    let deniedApps: MenuBarDeniedAppsModel

    @State private var snapshot: FirewallSnapshot

    init(firewall: any FirewallProviding, deniedApps: MenuBarDeniedAppsModel) {
        self.firewall = firewall
        self.deniedApps = deniedApps
        _snapshot = State(initialValue: firewall.snapshot)
    }

    private var presentation: FirewallStatusPresentation {
        FirewallStatusPresentation(state: snapshot.state)
    }

    private var accessibilityText: String {
        guard deniedApps.deniedCount > 0 else { return presentation.title }
        return "\(presentation.title)，已阻止 \(deniedApps.deniedCount) 个应用"
    }

    var body: some View {
        Image(systemName: presentation.symbol)
            .foregroundStyle(presentation.color)
            .overlay(alignment: .topTrailing) {
                if deniedApps.deniedCount > 0 {
                    Circle()
                        .fill(.red)
                        .frame(width: 5, height: 5)
                        .offset(x: 1, y: -1)
                }
            }
            .frame(width: 18, height: 20)
            .accessibilityLabel(accessibilityText)
            .help(accessibilityText)
            .task {
                deniedApps.start()
                for await update in firewall.observe() {
                    snapshot = update
                }
            }
    }
}
