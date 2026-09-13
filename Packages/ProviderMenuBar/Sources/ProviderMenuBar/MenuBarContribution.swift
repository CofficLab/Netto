import SwiftUI

/// 插件可注入的菜单栏常驻内容或 popover 内容。
@MainActor
public struct MenuBarContribution: Identifiable {
    public let id: String
    public let title: String
    public let order: Int
    public let ownerPluginID: String
    public let makeView: @MainActor () -> AnyView

    public init<Content: View>(
        id: String,
        title: String,
        order: Int = 200,
        ownerPluginID: String,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) {
        self.id = id
        self.title = title
        self.order = order
        self.ownerPluginID = ownerPluginID
        self.makeView = { AnyView(content()) }
    }
}

/// 菜单栏 popover 内容贡献的聚合能力。
///
/// App Host 拥有 NSStatusItem / NSPopover 等系统接入；插件只注册视图贡献。
@MainActor
public protocol MenuBarProviding: AnyObject, Sendable {
    var contentItems: [MenuBarContribution] { get }
    var popupItems: [MenuBarContribution] { get }

    func addContent(_ contribution: MenuBarContribution)
    func addPopup(_ contribution: MenuBarContribution)
    func removeItems(ownedBy pluginID: String)
    func makeContentView() -> AnyView
    func makePopupView() -> AnyView
}
