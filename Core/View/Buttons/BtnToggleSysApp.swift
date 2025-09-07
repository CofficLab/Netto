import MagicCore
import MagicAlert
import SwiftUI

struct BtnToggleSysApp: View, SuperLog {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var app: UIProvider
    @EnvironmentObject var ui: UIProvider
    
    private var asToolbarItem: Bool = false
    private var icon: String {
        ui.showSystemApps ? "eye.slash" : "eye.circle"
    }
    private var title: String {
        ui.showSystemApps ? "隐藏系统APP" : "显示系统APP"
    }
    
    init(asToolbarItem: Bool = false) {
        self.asToolbarItem = asToolbarItem
    }

    var body: some View {
        if asToolbarItem {
            Button {
                action()
            } label: {
                Label {
                    Text(title)
                } icon: {
                    Image(systemName: icon)
                }
            }
            .buttonStyle(.plain)
        } else {
            MagicButton.simple(icon: icon, size: .auto, action: {
                action()
            })
            .magicTitle(title)
            .magicShape(.roundedRectangle)
            .frame(width: 150)
            .frame(height: 50)
        }
    }
    
    private func action() -> Void {
        ui.showSystemApps.toggle()
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
