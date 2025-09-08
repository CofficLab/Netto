import MagicCore
import MagicAlert
import MagicUI
import SwiftUI

struct BtnStop: View, SuperLog {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var app: UIProvider
    @EnvironmentObject private var firewall: FirewallService
    
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
            .magicDisabled(firewall.status.isNotRunning() ? "未开启" : nil)
            .frame(width: 150)
            .frame(height: 50)
        }
    }
    
    private func action() -> Void {
        Task {
            do {
                try await firewall.stopFilter(reason: self.className)
            } catch {
                self.m.error(error)
            }
        }
    }
}

#Preview {
    RootView {
        VStack {
            BtnStop()
            BtnStop(asToolbarItem: true)
        }
    }
    .frame(height: 500)
    .frame(width: 500)
}

#Preview("App") {
    RootView {
        ContentView()
    }
}
