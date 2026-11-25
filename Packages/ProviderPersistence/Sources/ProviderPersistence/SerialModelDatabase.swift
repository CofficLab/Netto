import Foundation
import Synchronization
import SwiftData

/// SwiftData 的专用串行执行器。
///
/// 关键约束：`ModelContext` 只在数据库队列上首次使用时创建，因此它的
/// managed object queue 永远不是主队列；之后所有读写都经 `perform`
/// 进入同一条串行队列，主线程既不阻塞也不持有 context。
///
/// 不使用 `@ModelActor`：宏生成的 `ModelContext` 在调用方线程创建，
/// 从 MainActor 构造时会让全部查询回落到主队列同步执行。
///
/// 并发边界：实例状态只有 `Mutex` 保护的 context 与不可变的队列/容器，
/// 因此可直接声明为 `Sendable`。
public final class SerialModelDatabase: Sendable {
    public let container: ModelContainer

    private let queue: DispatchQueue
    private let contextStorage = Mutex<ModelContext?>(nil)

    private static let queueKey = DispatchSpecificKey<Void>()

    public init(container: ModelContainer, label: String) {
        self.container = container
        self.queue = DispatchQueue(label: label, qos: .userInitiated)
        self.queue.setSpecific(key: Self.queueKey, value: ())
    }

    /// 当前是否运行在数据库队列上。
    public var isOnDatabaseQueue: Bool {
        DispatchQueue.getSpecific(key: Self.queueKey) != nil
    }

    /// 在数据库队列上执行并异步返回结果。
    public func perform<T: Sendable>(
        _ body: @escaping @Sendable (ModelContext) throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    continuation.resume(returning: try self.withContext(body))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 延时在数据库队列上执行（用于延迟提交等后台维护）。
    public func perform(
        after delay: TimeInterval,
        _ body: @escaping @Sendable (ModelContext) -> Void
    ) {
        queue.asyncAfter(deadline: .now() + delay) {
            self.withContext(body)
        }
    }

    private func withContext<T: Sendable>(
        _ body: @Sendable (ModelContext) throws -> T
    ) rethrows -> T {
        try contextStorage.withLock { stored in
            let context: ModelContext
            if let stored {
                context = stored
            } else {
                let created = ModelContext(container)
                created.autosaveEnabled = false
                stored = created
                context = created
            }
            return try body(context)
        }
    }
}