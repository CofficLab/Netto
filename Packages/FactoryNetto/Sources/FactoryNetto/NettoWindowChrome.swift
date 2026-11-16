import AppKit
import SwiftUI

public extension View {
    /// Lumi 同款主窗口 chrome：内容延伸到标题栏区域，顶部工具栏从窗口最顶部
    /// 开始渲染，红绿灯悬浮在工具栏上（共享 `DefaultToolbarProviding` 已预留 76pt）。
    ///
    /// 除窗口样式外的清理必须在拿到 `NSWindow` 之后做：SwiftUI 的 `Window`
    /// 场景会给窗口装一条空工具栏，不清掉会在自定义工具栏上方多出一条标题栏。
    func nettoMinimalWindowChrome() -> some View {
        background(WindowChromeAccessor())
    }
}

/// 解析宿主 `NSWindow` 并应用 chrome 的辅助视图。
///
/// 只在视图挂上窗口时应用一次：`styleMask` 的写入会触发布局，若在
/// `updateNSView` 里反复写回，会形成 SwiftUI 更新 → 布局 → 再更新的死循环。
private struct WindowChromeAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        WindowChromeView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class WindowChromeView: NSView {
        private weak var configuredWindow: NSWindow?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            applyChrome()
        }

        func applyChrome() {
            guard let window, configuredWindow !== window else { return }
            configuredWindow = window
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.toolbar = nil
            window.styleMask.insert(.fullSizeContentView)
        }

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }
    }
}
