import Foundation
import MagicCore
import MagicAlert
import MagicUI
import OSLog
import PluginShell
import ProviderShell
import SwiftUI

struct StoreBtn: View, SuperLog {
    @EnvironmentObject private var shell: ShellCenter
    
    private var asToolbarItem: Bool = false
    private var icon: String = "app.gift"
    
    init(asToolbarItem: Bool = false) {
        self.asToolbarItem = asToolbarItem
    }

    var body: some View {
        Group {
            if asToolbarItem {
                Button {
                    action()
                } label: {
                    Label {
                        Text("Store")
                    } icon: {
                        Image(systemName: icon)
                    }
                }
                .buttonStyle(.plain)
            } else {
                MagicButton.simple(icon: icon, size: .auto, action: {
                    action()
                })
                .magicTitle("商店")
                .magicShape(.roundedRectangle)
                .frame(width: 150)
                .frame(height: 50)
            }
        }
    }
    
    private func action() -> Void {
        // 通过 WindowProviding 请求打开商店窗口（替代旧通知机制）
        shell.requestOpen(WindowRequest(windowID: "plugin-window", title: "Store - TravelMode"))
    }
}

// MARK: - Preview




