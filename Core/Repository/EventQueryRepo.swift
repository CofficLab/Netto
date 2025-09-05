/*
 说明：为何同时存在 EventQueryRepo（class）与 EventQueryActor（actor）

 - 分层动机：
   - EventQueryActor（符合 SwiftData 的 ModelActor）：
     作为数据访问边界，内部使用 modelContext 串行执行查询，确保并发安全与线程正确性；
     不直接暴露给 SwiftUI 作为环境对象使用。

   - EventQueryRepo（ObservableObject/class）：
     面向 UI 的仓库门面，便于通过 .environmentObject 注入与生命周期管理；
     对外提供 async/回调 API，并负责在 MainActor 回传结果，屏蔽并发细节。

 - 不合并为一个的原因：
   - actor 无法作为 ObservableObject 直接注入环境，且与现有 Provider 生态不一致；
   - 若仅保留 class，需要手动管理并发与串行化，可靠性不如 ModelActor。

 - 结论：
   双层结构（Repo 作为 UI 门面 + Actor 作为数据执行器）在可用性与并发安全之间取得平衡，
   既便于 SwiftUI 集成，又由 ModelActor 提供清晰的并发隔离与串行执行保障。
*/
import Foundation
import SwiftData
import SwiftUI
import NetworkExtension
import MagicCore
import OSLog

/// 基于 actor 的只读查询仓库，不影响现有 EventRepo
final class EventQueryRepo: ObservableObject, SuperLog {
    private let actor: EventQueryActor

    /// 使用自定义 ModelContainer 初始化
    init(container: ModelContainer) {
        self.actor = EventQueryActor(container: container)
    }

    /// 使用默认容器初始化
    @MainActor
    convenience init() {
        self.init(container: DBManager.container())
    }

    /// 异步查询，返回计数与分页结果
    func load(
        appId: String,
        page: Int,
        pageSize: Int,
        status: FirewallEvent.Status?,
        direction: NETrafficDirection?
    ) async throws -> EventPageResult {
        os_log("\(self.t) loadAsync appId: \(appId)")
        return try await actor.load(appId: appId, page: page, pageSize: pageSize, status: status, direction: direction)
    }

    /// 后台查询并在主线程回调
    func loadAsync(
        appId: String,
        page: Int,
        pageSize: Int,
        status: FirewallEvent.Status?,
        direction: NETrafficDirection?,
        completion: @escaping @MainActor @Sendable (Int, [FirewallEventDTO]) -> Void
    ) {
        let queryActor = self.actor
        Task.detached(priority: .utility) {
            let result: EventPageResult
            do {
                result = try await queryActor.load(appId: appId, page: page, pageSize: pageSize, status: status, direction: direction)
            } catch {
                result = EventPageResult(totalCount: 0, events: [])
            }
            await MainActor.run {
                completion(result.totalCount, result.events)
            }
        }
    }
}

/// 串行执行 SwiftData 查询的 actor（对外隐藏实现细节）
private actor EventQueryActor: ModelActor, SuperLog {
    let modelContainer: ModelContainer
    nonisolated let modelExecutor: ModelExecutor

    init(container: ModelContainer) {
        self.modelContainer = container
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: ModelContext(container))
    }

    func load(
        appId: String,
        page: Int,
        pageSize: Int,
        status: FirewallEvent.Status?,
        direction: NETrafficDirection?
    ) throws -> EventPageResult {
        os_log("\(self.t) load appId: \(appId)")
        // 组合查询谓词（与 EventRepo 逻辑保持一致）
        var predicates: [Predicate<FirewallEventModel>] = [
            #Predicate<FirewallEventModel> { item in item.sourceAppIdentifier == appId }
        ]

        if let status = status {
            let statusValue = status == .allowed ? 0 : 1
            predicates.append(#Predicate<FirewallEventModel> { item in item.statusRawValue == statusValue })
        }

        if let direction = direction {
            let directionValue = direction.rawValue
            predicates.append(#Predicate<FirewallEventModel> { item in item.directionRawValue == directionValue })
        }

        let combinedPredicate = predicates.reduce(into: predicates[0]) { result, predicate in
            result = #Predicate<FirewallEventModel> { item in
                result.evaluate(item) && predicate.evaluate(item)
            }
        }

        // 计数
        let countDescriptor = FetchDescriptor<FirewallEventModel>(predicate: combinedPredicate)
        let totalCount = try modelContext.fetchCount(countDescriptor)

        // 列表
        var listDescriptor = FetchDescriptor<FirewallEventModel>(
            predicate: combinedPredicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        listDescriptor.fetchOffset = page * pageSize
        listDescriptor.fetchLimit = pageSize

        let models = try modelContext.fetch(listDescriptor)
        let dtos = models.map(FirewallEventDTO.fromModel)
        return EventPageResult(totalCount: totalCount, events: dtos)
    }
}

/// 结果传输对象：跨并发边界传递，声明为 @unchecked Sendable 以放宽检查
struct EventPageResult: Sendable {
    let totalCount: Int
    let events: [FirewallEventDTO]
}
