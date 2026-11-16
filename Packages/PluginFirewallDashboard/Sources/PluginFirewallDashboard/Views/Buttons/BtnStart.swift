import LumiUI
import ProviderShell
import ProviderViewEnvironment
import ProviderFirewall
import SwiftUI

public struct BtnStart: View {
    @Environment(\.firewallProvider) private var firewall: FirewallProviding?
    @EnvironmentObject private var shell: ShellCenter

    @State private var isBusy = false

    private var asToolbarItem: Bool = false
    private var title: String = "开启"

    public init(asToolbarItem: Bool = false, title: String = "开启") {
        self.asToolbarItem = asToolbarItem
        self.title = title
    }

    public var body: some View {
        if asToolbarItem {
            AppIconButton(systemImage: "restart.circle") {
                action()
            }
            .disabled(isBusy)
        } else {
            AppButton(isBusy ? "开启中…" : title, systemImage: "restart.circle", style: .primary, fillsWidth: true, action: {
                action()
            })
            .disabled(isBusy || firewall?.snapshot.state.isRunning() == true)
            .help(isBusy ? "正在开启…" : (firewall?.snapshot.state.isRunning() == true ? "已开启" : ""))
            .frame(width: 150)
            .frame(height: 50)
        }
    }

    private func action() {
        guard let firewall, !isBusy else { return }
        isBusy = true
        Task {
            do {
                try await firewall.start()
            } catch {
                shell.postError("开启防火墙失败：\(error.localizedDescription)")
            }
            isBusy = false
        }
    }
}

#Preview("APP") {
    ContentView()
        .dashboardPreviewRoot()
        .frame(height: 500)
}

#Preview {
    BtnStart()
        .dashboardPreviewRoot()
}
