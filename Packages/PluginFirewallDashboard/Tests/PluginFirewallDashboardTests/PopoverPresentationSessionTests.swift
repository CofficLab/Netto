import AppKit
import Foundation
import Testing
@testable import PluginFirewallDashboard

/// 菜单栏弹窗呈现会话测试：弹窗关闭必须结束本次呈现并复位选中的应用。
@MainActor
@Suite("PopoverPresentationSession")
struct PopoverPresentationSessionTests {

    @Test("弹窗窗口离屏时结束本次呈现")
    func endsWhenWindowGoesOffScreen() {
        let center = NotificationCenter()
        let session = PopoverPresentationSession(notificationCenter: center)
        let window = NSWindow(contentRect: .zero, styleMask: [.titled], backing: .buffered, defer: false)
        session.attach(window: window)

        var ended = false
        session.onEnd = { ended = true }

        center.post(name: PopoverPresentationSession.willOrderOffScreen, object: window)

        #expect(ended)
    }

    @Test("其他窗口离屏不影响本次呈现")
    func ignoresOtherWindows() {
        let center = NotificationCenter()
        let session = PopoverPresentationSession(notificationCenter: center)
        let window = NSWindow(contentRect: .zero, styleMask: [.titled], backing: .buffered, defer: false)
        let other = NSWindow(contentRect: .zero, styleMask: [.titled], backing: .buffered, defer: false)
        session.attach(window: window)

        var ended = false
        session.onEnd = { ended = true }

        center.post(name: PopoverPresentationSession.willOrderOffScreen, object: other)

        #expect(ended == false)
    }

    @Test("呈现结束时复位选中的应用")
    func resetsSelectedAppOnEnd() {
        let center = NotificationCenter()
        let session = PopoverPresentationSession(notificationCenter: center)
        let window = NSWindow(contentRect: .zero, styleMask: [.titled], backing: .buffered, defer: false)
        session.attach(window: window)

        let ui = UIProvider()
        ui.selectApp("com.example.app")
        session.onEnd = { ui.clearSelectedApp() }

        center.post(name: PopoverPresentationSession.willOrderOffScreen, object: window)

        #expect(ui.selectedAppId == nil)
    }

    @Test("未挂载窗口时离屏通知不结束呈现")
    func ignoresOffScreenWithoutAttachedWindow() {
        let center = NotificationCenter()
        let session = PopoverPresentationSession(notificationCenter: center)

        var ended = false
        session.onEnd = { ended = true }

        center.post(
            name: PopoverPresentationSession.willOrderOffScreen,
            object: NSWindow(contentRect: .zero, styleMask: [.titled], backing: .buffered, defer: false)
        )

        #expect(ended == false)
    }

    @Test("离屏通知名与 AppKit 常量一致")
    func notificationNameMatchesAppKit() {
        // AppKit 未在 Swift 中导出该常量名，这里锁定官方通知名，
        // 保证会话监听的正是 AppKit 真实投递的窗口离屏通知。
        #expect(PopoverPresentationSession.willOrderOffScreen.rawValue
            == "NSWindowWillOrderOffScreenNotification")
    }
}
