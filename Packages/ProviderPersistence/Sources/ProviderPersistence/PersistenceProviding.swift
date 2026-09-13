import SwiftData

/// 各数据插件共享的 SwiftData 容器契约。
///
/// 该低层契约仅在持久化实现插件与数据存储插件之间使用，视图层只消费各自领域 Provider。
@MainActor
public protocol PersistenceProviding: AnyObject, Sendable {
    var container: ModelContainer { get }
}
