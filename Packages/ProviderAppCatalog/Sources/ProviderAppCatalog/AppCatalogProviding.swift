import Foundation

/// 应用展示条目的中立值。
///
/// 图标以 PNG `Data` 传递（Sendable），不暴露 NSImage/AppKit 类型。
public struct AppCatalogEntry: Sendable, Equatable, Identifiable {
    /// 应用标识符（bundle id / 进程名）。
    public let identifier: String
    /// 展示名。
    public let displayName: String
    /// 图标 PNG 数据（可选）。
    public let iconData: Data?
    /// 是否系统级应用（用于旧 SmartApp-System 分支展示差异）。
    public let isSystemApp: Bool

    public init(identifier: String, displayName: String, iconData: Data? = nil, isSystemApp: Bool = false) {
        self.identifier = identifier
        self.displayName = displayName
        self.iconData = iconData
        self.isSystemApp = isSystemApp
    }

    public var id: String { identifier }
}

/// 应用目录能力契约：从应用标识符解析元数据与图标。
///
/// 线程/actor：实现为 `@MainActor` 对象；内部可调用 Launch Services/NSWorkspace。
@MainActor
public protocol AppCatalogProviding: AnyObject, Sendable {
    /// 解析单个应用条目（未知应用返回 fallback 条目，不抛错）。
    func entry(for identifier: String) async -> AppCatalogEntry

    /// 批量解析（保留输入顺序，未知应用返回 fallback 条目）。
    func entries(for identifiers: [String]) async -> [AppCatalogEntry]

    /// 单条应用图标 PNG 数据。
    func iconData(for identifier: String) async -> Data?
}
