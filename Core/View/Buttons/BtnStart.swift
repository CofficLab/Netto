import MagicCore
import MagicAlert
import MagicUI
import OSLog
import SwiftUI

struct BtnStart: View, SuperLog {
    @EnvironmentObject private var m: MagicMessageProvider
    @EnvironmentObject private var firewall: FirewallService

    private var asToolbarItem: Bool = false

    init(asToolbarItem: Bool = false) {
        self.asToolbarItem = asToolbarItem
    }

    var body: some View {
        if asToolbarItem {
            Button {
                action()
            } label: {
                Label {
                    Text("开始")
                } icon: {
                    Image(systemName: "restart.circle")
                }
            }
            .buttonStyle(.plain)
        } else {
            MagicButton.simple(icon: "restart.circle", size: .auto, action: {
                action()
            })
            .magicTitle("开启")
            .magicBackgroundColor(.blue)
            .magicShape(.roundedRectangle)
            .magicDisabled(firewall.status.isRunning() ? "已开启" : nil)
            .frame(width: 150)
            .frame(height: 50)
        }
    }

    private func action() {
        Task {
            do {
                try await firewall.startFilter(reason: self.className)
            } catch let error {
                m.error(error)
            }
        }
    }
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(height: 500)
}

#Preview {
    BtnStart()
        .inRootView()
}
