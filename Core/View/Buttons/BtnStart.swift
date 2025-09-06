import SwiftUI
import MagicCore
import OSLog

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
            .frame(width: 150)
            .frame(height: 50)
        }
    }
    
    private func action() -> Void {
        Task {
            do {
                try await firewall.startFilter(reason: self.className)
            } catch (let error) {
                os_log("\(self.t)开启过滤器失败 -> \(error.localizedDescription)")
                m.error(error)
            }
        }
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 500)
}

#Preview {
    RootView {
        BtnStart()
    }
}
