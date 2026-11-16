import LumiUI
import SwiftUI

struct BtnQuit: View {
    
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
            AppButton(title, systemImage: icon, style: .primary, fillsWidth: true, action: {
                action()
            })
            .frame(width: 150)
            .frame(height: 50)
            .accessibilityIdentifier("netto.settings.quit")
        }
    }
    
    private func action() -> Void {
        // 退出应用程序
        NSApp.terminate(nil)
    }
}

#Preview {
    BtnQuit()
}
