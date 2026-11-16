import ProviderFirewall
import SwiftUI

/// 主窗口工具栏的防火墙开关：与工具栏右侧设置按钮同用 `AppIconButton` 样式。
struct TileSwitcher: View {
    @Environment(\.firewallProvider) private var firewall: FirewallProviding?
    @State private var snapshot: FirewallSnapshot?

    private var resolvedSnapshot: FirewallSnapshot? {
        snapshot ?? firewall?.snapshot
    }

    var body: some View {
        Group {
            if resolvedSnapshot?.state.isRunning() == true {
                BtnStop(asToolbarItem: true)
                    .accessibilityLabel("停止")
                    .accessibilityIdentifier("netto.firewall.stop")
            } else {
                BtnStart(asToolbarItem: true)
                    .accessibilityLabel("开启")
                    .accessibilityIdentifier("netto.firewall.start")
                    .disabled(resolvedSnapshot?.canStart != true)
            }
        }
        .task { await observe() }
    }

    private func observe() async {
        guard let firewall else { return }
        snapshot = firewall.snapshot
        for await update in firewall.observe() {
            snapshot = update
        }
    }
}
