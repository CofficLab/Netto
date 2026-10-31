import Foundation

/// Shell 宿主使用的窗口 ID 常量。
///
/// 窗口 ID 同时是 SwiftUI `Window(id:)` 的 Scene 标识与 AppKit 侧
/// `NSWindow.identifier` 的取值（实测 SwiftUI 托管窗口的 identifier
/// 等于 Scene id），因此宿主既能用 `openWindow(id:)` 打开，也能用
/// identifier 精确定位已存在的窗口。
public enum ShellWindowID {
    /// 设置窗口（双栏设置视图：左侧入口列表 + 右侧详情）。
    public static let settings = "settings-window"

    /// 插件窗口（插件贡献的内容视图）。
    public static let plugin = "plugin-window"

    /// 欢迎/引导窗口。
    public static let welcome = "welcome"
}

/// 窗口标题常量。
///
/// 宿主 SwiftUI 场景（`Window("标题", id:)`）与 Provider 契约共用同一来源，
/// 避免「契约里的 ID」与「场景里的标题」各写一份而漂移。
public enum ShellWindowTitle {
    /// 设置窗口标题。
    public static let settings = "设置"

    /// 插件窗口标题。
    public static let plugin = "Plugin Window"

    /// 欢迎/引导窗口标题。
    public static let welcome = "Welcome to TravelMode"
}

/// 设置入口深链请求：打开设置窗口并选中指定入口。
///
/// 插件与宿主之间不直接传递 SwiftUI 的 `OpenWindowAction`（那属于
/// 视图层能力，插件侧拿不到 `Environment`）；插件只声明「我想打开
/// 设置窗口的某个入口」，由宿主把它翻译成真正的窗口路由动作。
public struct SettingsOpenRequest: Sendable, Equatable {
    /// 要选中的设置入口 ID；nil 表示沿用当前选中项。
    public let entryID: String?

    public init(entryID: String? = nil) {
        self.entryID = entryID
    }
}

/// 窗口路由能力：宿主实现，插件消费。
///
/// 插件通过该契约请求打开宿主窗口，**不依赖 SwiftUI `openWindow`**
/// （插件视图拿不到 `Environment`，且 `Window` Scene 的 id 属于宿主
/// 私有实现细节）。宿主把请求翻译成实际的 `openWindow(id:)` 调用。
///
/// 线程/actor：`@MainActor`（窗口操作必须在主线程）。
@MainActor
public protocol WindowRoutingProviding: AnyObject, Sendable {
    /// 请求打开设置窗口。
    ///
    /// - Parameter request: 深链请求；`entryID` 非空时先选中对应入口再打开。
    func openSettings(_ request: SettingsOpenRequest)

    /// 请求打开指定 ID 的窗口。
    ///
    /// - Parameter windowID: 目标窗口 ID（见 `ShellWindowID`）。
    /// - Parameter entryID: 可选的设置入口深链参数；仅设置窗口有意义。
    func openWindow(windowID: String, entryID: String?)
}

public extension WindowRoutingProviding {
    /// 打开设置窗口（不指定入口）。
    func openSettings() {
        openSettings(SettingsOpenRequest())
    }

    /// 打开设置窗口并选中指定入口。
    func openSettings(entryID: String) {
        openSettings(SettingsOpenRequest(entryID: entryID))
    }

    /// 打开指定 ID 的窗口（不带深链参数）。
    func openWindow(windowID: String) {
        openWindow(windowID: windowID, entryID: nil)
    }
}
