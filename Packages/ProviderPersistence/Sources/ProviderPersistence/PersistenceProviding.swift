import SwiftData

/// 事件插件独占的 SwiftData 容器契约。
///
/// 每个数据插件只解析自己的契约，不跨插件共享 ModelContainer。
@MainActor
public protocol EventStorePersistenceProviding: AnyObject, Sendable {
    var container: ModelContainer { get }
}

/// 设置插件独占的 SwiftData 容器契约。
@MainActor
public protocol AppSettingsPersistenceProviding: AnyObject, Sendable {
    var container: ModelContainer { get }
}
