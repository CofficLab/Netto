import AppKit
import SwiftUI
import Testing
@testable import PluginFirewallDashboard

/// 菜单栏弹窗选中状态的回归测试：
/// 弹窗关闭（窗口离屏）后必须复位选中的应用，下次打开回到应用列表。
@MainActor
@Suite("菜单栏弹窗选中状态")
struct MenuBarPopoverSelectionTests {

    @Test("弹窗关闭后复位选中的应用")
    func resetsSelectionWhenPopoverCloses() {
        let ui = UIProvider()
        ui.selectApp("com.example.app")

        let hosting = NSHostingView(rootView: ContentView().environmentObject(ui))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 360),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.contentView = hosting
        hosting.layoutSubtreeIfNeeded()
        // 让 SwiftUI 完成一次布局（onAppear 会在这里绑定会话回调）。
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        #expect(ui.selectedAppId == "com.example.app")

        NotificationCenter.default.post(
            name: PopoverPresentationSession.willOrderOffScreen,
            object: window
        )

        #expect(ui.selectedAppId == nil)
    }
}
