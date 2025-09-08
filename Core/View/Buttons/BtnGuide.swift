import SwiftUI
import MagicCore
import MagicUI

/**
 * 引导按钮组件
 * 显示应用程序的引导界面
 */
struct BtnGuide: View, SuperEvent {
    @Environment(\.openWindow) private var openWindow
    
    private var asToolbarItem: Bool = false
    private var icon: String = "questionmark.circle"
    private var title: String = "使用引导"
    
    /**
     * 初始化引导按钮
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
            MagicButton.simple(icon: icon, size: .auto, action: {
                action()
            })
            .magicTitle(title)
            .magicShape(.roundedRectangle)
            .frame(width: 150)
            .frame(height: 50)
        }
    }
    
    /**
     * 显示引导界面的操作
     * 打开欢迎引导窗口并隐藏菜单栏窗口
     */
    private func action() -> Void {
        nc.post(name: .shouldOpenWelcomeWindow, object: nil)
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
