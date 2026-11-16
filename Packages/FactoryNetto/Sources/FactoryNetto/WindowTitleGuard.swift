import AppKit
import SwiftUI

/// 窗口标题守卫 —— 强制宿主窗口保持既定标题。
///
/// ## 为什么需要它
///
/// 设置窗口的详情区由插件贡献的视图填充。这些视图可能带有
/// `.navigationTitle(...)`（例如「数据库」入口里的事件列表），而 SwiftUI
/// 会把内容里的 `navigationTitle` **提升**为宿主窗口的标题 —— 结果是
/// 点一下入口，窗口标题就从「设置」变成了「防火墙事件」，与窗口语义不符，
/// 也让按标题定位窗口的逻辑失效。
///
/// 守卫在每次内容更新后把标题改回宿主定义的值。详情视图的标题语义由
/// 视图内部的标题控件表达，不应改写宿主窗口标题。
///
/// ## 线程/actor
///
/// `@MainActor`：窗口操作必须在主线程。
@MainActor
struct WindowTitleGuard: NSViewRepresentable {
    /// 期望的窗口标题。
    let title: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        // 视图进入窗口后再设置标题：此时窗口已就绪。
        DispatchQueue.main.async { apply(to: view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        apply(to: nsView.window)
    }

    private func apply(to window: NSWindow?) {
        guard let window, window.title != title else { return }
        window.title = title
    }
}
