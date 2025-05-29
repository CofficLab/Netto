import SwiftUI
import MagicCore

/**
 * 关于按钮组件
 * 显示应用程序的关于界面（系统自带）
 */
struct BtnAbout: View {
    @EnvironmentObject var app: UIProvider
    
    private var asToolbarItem: Bool = false
    private var icon: String = "info.circle"
    private var title: String = "关于"
    
    /**
     * 初始化关于按钮
     * @param asToolbarItem 是否作为工具栏项目显示
     */
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
    
    /**
     * 显示关于界面的操作
     * 使用系统自带的关于面板
     */
    private func action() -> Void {
        // 显示系统自带的关于面板
        NSApplication.shared.orderFrontStandardAboutPanel(nil)
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
