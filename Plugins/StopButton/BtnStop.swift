import MagicAlert
import MagicCore
import MagicUI
import PluginShell
import ProviderFirewall
import SwiftUI

struct BtnStop: View, SuperLog {
    @EnvironmentObject var app: UIProvider
    @EnvironmentObject private var shell: ShellCenter
    @Environment(\.firewallProvider) private var firewall: FirewallProviding?

    private var asToolbarItem: Bool = false
    private var icon: String = "stop.circle"

    init(asToolbarItem: Bool = false) {
        self.asToolbarItem = asToolbarItem
    }

    var body: some View {
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
    RootView(environment: .preview()) {
        VStack {
            BtnStop()
            BtnStop(asToolbarItem: true)
        }
    }
    .frame(height: 500)
    .frame(width: 500)
}

#Preview("App") {
    ContentView()
        .inRootView()
        .frame(height: 800)
        .frame(width: 500)
}
