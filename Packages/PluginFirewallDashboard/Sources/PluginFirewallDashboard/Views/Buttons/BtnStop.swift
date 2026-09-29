import LumiUI
import ProviderViewEnvironment
import ProviderShell
import ProviderFirewall
import SwiftUI

public struct BtnStop: View {
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
            AppButton("停止", systemImage: icon, style: .primary, fillsWidth: true, action: {
                action()
            })
            .disabled(firewall?.snapshot.state.isNotRunning() == true)
            .help(firewall?.snapshot.state.isNotRunning() == true ? "未开启" : "")
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
