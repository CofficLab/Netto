import MagicAlert
import ProviderViewEnvironment
import MagicCore
import MagicUI
import ProviderShell
import ProviderFirewall
import SwiftUI

public struct BtnStop: View, SuperLog {
    @EnvironmentObject var app: UIProvider
    @EnvironmentObject private var shell: ShellCenter
    @Environment(\.firewallProvider) private var firewall: FirewallProviding?

    private var asToolbarItem: Bool = false
    private var icon: String = "stop.circle"

    public init(asToolbarItem: Bool = false) {
        self.asToolbarItem = asToolbarItem
    }

    public var body: some View {
        if asToolbarItem {
            Button {
                action()
            } label: {
                Label {
                    Text("Stop")
                } icon: {
                    Image(systemName: icon)
                }
            }
            .buttonStyle(.plain)
        } else {
            MagicButton.simple(icon: icon, size: .auto, action: {
                action()
            })
            .magicTitle("停止")
            .magicShape(.roundedRectangle)
            .magicDisabled(firewall?.snapshot.state.isNotRunning() == true ? "未开启" : nil)
            .frame(width: 150)
            .frame(height: 50)
        }
    }

    private func action() {
        guard let firewall else { return }
        Task {
            do {
                try await firewall.stop()
            } catch {
                shell.postError("停止防火墙失败：\(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    VStack {
        BtnStop()
        BtnStop(asToolbarItem: true)
    }
    .dashboardPreviewRoot()
}

#Preview("App") {
    ContentView()
        .dashboardPreviewRoot()
        .frame(height: 800)
        .frame(width: 500)
}
