import SwiftUI
import MagicCore
import MagicUI

struct BtnQuit: View {
    @EnvironmentObject var app: UIProvider
    
    private var asToolbarItem: Bool = false
    private var icon: String = "xmark.circle"
    private var title: String = "退出"
    
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
        // 退出应用程序
        NSApp.terminate(nil)
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
