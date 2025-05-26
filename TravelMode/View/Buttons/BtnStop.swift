import MagicCore
import SwiftUI

struct BtnStop: View, SuperLog {
    @EnvironmentObject private var channel: ChannelProvider
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var app: AppManager
    
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
                    Text("Stop")
                } icon: {
                    Image(systemName: "stop.circle")
                }
            }
        } else {
            MagicButton(icon: "restart.circle", size: .auto, action: {
                action()
            })
            .magicTitle("停止")
            .magicShape(.roundedRectangle)
            .frame(width: 150)
            .frame(height: 50)
        }
    }
    
    private func action() -> Void {
        Task {
            do {
                try await channel.stopFilter(reason: self.className)
                app.stop()
            } catch {
                self.m.error(error)
            }
        }
    }
}

#Preview("App") {
    RootView {
        ContentView()
    }
}

#Preview {
    RootView {
        BtnStop()
    }
}
