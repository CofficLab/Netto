import Foundation
import SwiftUI

/// 设置入口贡献。
public struct SettingsEntry: Sendable, Identifiable {
    /// 稳定入口 ID。
    public let id: String
    /// 排序（升序）。
    public let order: Int
    /// owner 插件 ID。
    public let ownerPluginID: String
    /// 入口视图工厂。
    public let makeView: @MainActor () -> AnyView

    public init(
        id: String,
        order: Int,
        ownerPluginID: String,
        makeView: @escaping @MainActor () -> AnyView
    ) {
        self.id = id
        self.order = order
        self.ownerPluginID = ownerPluginID
        self.makeView = makeView
    }
}

/// 设置入口聚合能力（BtnSettings 只依赖本协议）。
@MainActor
public protocol SettingsProviding: AnyObject, Sendable {
    /// 全部设置入口（按 order 升序）。
    var entries: [SettingsEntry] { get }

    /// 注册一个设置入口。
    func registerEntry(_ entry: SettingsEntry)

    /// 撤回某个 owner 插件的全部设置入口。
    func removeEntries(ownedBy pluginID: String)
}

/// 窗口请求（typed，替代 NotificationCenter 对象传递）。
public struct WindowRequest: Sendable, Equatable {
    public let windowID: String
    public let title: String

    public init(windowID: String, title: String) {
        self.windowID = windowID
        self.title = title
    }
}

/// 插件窗口内容贡献。
public struct WindowContentContribution: Sendable, Identifiable {
    /// 窗口稳定 ID（旧 PluginWindowContent 语义）。
    public let id: String
    /// 窗口标题。
    public let title: String
    /// owner 插件 ID。
    public let ownerPluginID: String
    /// 内容视图工厂。
    public let makeView: @MainActor () -> AnyView

    public init(
        id: String,
        title: String,
        ownerPluginID: String,
        makeView: @escaping @MainActor () -> AnyView
    ) {
        self.id = id
        self.title = title
        self.ownerPluginID = ownerPluginID
        self.makeView = makeView
    }
}

/// 窗口能力契约（App Host 提供实现；插件只发出 typed 请求）。
@MainActor
public protocol WindowProviding: AnyObject, Sendable {
    /// 当前要展示的插件窗口内容。
    var currentContent: WindowContentContribution? { get }

    /// 请求打开窗口（Host 负责 showWindow/openWindow）。
    func requestOpen(_ request: WindowRequest)

    /// 注册窗口内容贡献。
    func registerContent(_ content: WindowContentContribution)

    /// 撤回某个 owner 插件的窗口内容。
    func removeContent(ownedBy pluginID: String)

    /// 隐藏当前插件窗口。
    func hideWindow()
}

/// Toast 消息（中立值；替代 MagicMessageProvider 的 SmartMessage 直接传递）。
public struct ToastMessage: Sendable, Equatable {
    public let description: String
    public let isError: Bool
    public let duration: Int
    public let channel: String

    public init(description: String, isError: Bool = false, duration: Int = 3, channel: String = "default") {
        self.description = description
        self.isError = isError
        self.duration = duration
        self.channel = channel
    }
}

/// Toast 能力契约。
@MainActor
public protocol ToastProviding: AnyObject, Sendable {
    /// 发送一条 Toast。
    func post(_ message: ToastMessage)

    /// 便捷：成功提示。
    func postSuccess(_ description: String)

    /// 便捷：错误提示。
    func postError(_ description: String)
}

public extension ToastProviding {
    func postSuccess(_ description: String) {
        post(ToastMessage(description: description, isError: false))
    }

    func postError(_ description: String) {
        post(ToastMessage(description: description, isError: true))
    }
}
