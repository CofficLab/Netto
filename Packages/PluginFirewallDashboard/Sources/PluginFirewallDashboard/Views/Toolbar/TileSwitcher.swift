import ProviderFirewall
import SwiftUI

/// 主窗口工具栏的防火墙开关：与工具栏右侧设置按钮同用 `AppIconButton` 样式。
struct TileSwitcher: View {
    @Environment(\.firewallProvider) private var firewall: FirewallProviding?

    var body: some View {
        Group {
            if firewall?.snapshot.state.isRunning() == true {
                BtnStop(asToolbarItem: true)
                    .accessibilityLabel("停止")
                    .accessibilityIdentifier("netto.firewall.stop")
            } else {
                BtnStart(asToolbarItem: true)
                    .accessibilityLabel("开启")
                    .accessibilityIdentifier("netto.firewall.start")
                    .disabled(firewall?.snapshot.canStart != true)
            }
        }
    }
}
