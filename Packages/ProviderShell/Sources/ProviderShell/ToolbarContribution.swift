import Foundation
import SwiftUI

/// 工具栏位置（旧 `TopBarPosition` 语义）。
public enum ToolbarPosition: String, Sendable, Equatable, Hashable {
    case left
    case center
    case right
}

/// 工具栏贡献：稳定 ID + 位置 + 排序 + 视图工厂。
///
/// Kernel 不识别本类型；贡献由插件注册到 `ShellToolbarProviding` 实现，
/// Kernel 只登记对应的撤回 Token。
public struct ToolbarContribution: Sendable, Identifiable {
    /// 稳定贡献 ID。
    public let id: String
    /// 所在位置。
    public let position: ToolbarPosition
    /// 同位置内的排序（升序）。
    public let order: Int
    /// owner 插件 ID（撤回依据）。
    public let ownerPluginID: String
    /// 视图工厂（MainActor；每次调用返回新视图）。
    public let makeView: @MainActor () -> AnyView

    public init(
        id: String,
        position: ToolbarPosition,
        order: Int,
        ownerPluginID: String,
        makeView: @escaping @MainActor () -> AnyView
    ) {
        self.id = id
        self.position = position
        self.order = order
        self.ownerPluginID = ownerPluginID
        self.makeView = makeView
    }
}

/// 工具栏贡献聚合能力（TopBar 只依赖本协议读取排序后贡献）。
@MainActor
public protocol ShellToolbarProviding: AnyObject, Sendable {
    /// 左侧贡献（按 order 升序）。
    var leftContributions: [ToolbarContribution] { get }
    /// 中间贡献（按 order 升序）。
    var centerContributions: [ToolbarContribution] { get }
    /// 右侧贡献（按 order 升序）。
    var rightContributions: [ToolbarContribution] { get }

    /// 注册一个工具栏贡献。
    func registerToolbar(_ contribution: ToolbarContribution)

    /// 撤回某个 owner 插件的全部工具栏贡献。
    func removeToolbar(ownedBy pluginID: String)

    /// 按贡献 ID 撤回。
    func removeToolbar(id: String)
}
