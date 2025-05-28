import SwiftUI
import MagicCore

struct BtnToggleLog: View {
    @EnvironmentObject var app: AppManager
    
    private var asToolbarItem: Bool = false
    private var icon: String = "list.bullet.rectangle"
    private var title: String {
        app.logVisible ? "隐藏日志" : "显示日志"
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
            MagicButton(icon: icon, size: .auto, action: {
                action()
            })
            .magicTitle(title)
            .magicShape(.roundedRectangle)
            .frame(width: 150)
            .frame(height: 50)
        }
    }
    
    private func action() -> Void {
        app.logVisible.toggle()
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
