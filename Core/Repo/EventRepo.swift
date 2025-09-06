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
import MagicCore
import NetworkExtension
import OSLog
import SwiftData
import SwiftUI

/// 基于 actor 的仓库
final class EventRepo: ObservableObject, SuperLog {
    private let actor: EventQueryActor

    /// 使用自定义 ModelContainer 初始化
    init(container: ModelContainer) {
        self.actor = EventQueryActor(container: container)
    }

    /// 使用默认容器初始化
    convenience init() {
        self.init(container: container())
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

    // MARK: - CRUD Operations

    /// 创建新的FirewallEvent记录
    /// - Parameter event: FirewallEvent结构体实例
    /// - Throws: 保存数据时可能抛出的错误
    func create(_ event: FirewallEvent) async throws {
        os_log("\(self.t) create event: \(event.id)")
        try await actor.create(event)
    }

    /// 删除指定应用的所有事件记录
    /// - Parameter appId: 应用程序ID
    /// - Throws: 删除数据时可能抛出的错误
    func deleteByAppId(_ appId: String) async throws {
        os_log("\(self.t) deleteByAppId: \(appId)")
        try await actor.deleteByAppId(appId)
    }

    /// 删除指定应用ID超过指定天数的事件记录
    /// - Parameters:
    ///   - appId: 应用程序ID
    ///   - days: 保留天数，超过此天数的记录将被删除
    /// - Returns: 删除的记录数量
    /// - Throws: 删除数据时可能抛出的错误
    func deleteOldEventsByAppId(_ appId: String, olderThanDays days: Int) async throws -> Int {
        os_log("\(self.t) deleteOldEventsByAppId: \(appId), days: \(days)")
        return try await actor.deleteOldEventsByAppId(appId, olderThanDays: days)
    }

    /// 批量清理所有应用超过指定天数的事件记录
    /// - Parameter days: 保留天数，超过此天数的记录将被删除
    /// - Returns: 删除的总记录数量
    /// - Throws: 删除数据时可能抛出的错误
    func cleanupOldEvents(olderThanDays days: Int) async throws -> Int {
        os_log("\(self.t) cleanupOldEvents, days: \(days)")
        return try await actor.cleanupOldEvents(olderThanDays: days)
    }

    // MARK: - Query Operations

    /// 根据应用ID查找FirewallEvent记录
    /// - Parameter appId: 应用程序ID
    /// - Returns: 该应用的所有FirewallEventDTO记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchByAppId(_ appId: String) async throws -> [FirewallEventDTO] {
        os_log("\(self.t) fetchByAppId: \(appId)")
        return try await actor.fetchByAppId(appId)
    }
    
    /// 根据状态查找FirewallEvent记录
    /// - Parameter status: 防火墙状态
    /// - Returns: 指定状态的所有FirewallEventDTO记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchByStatus(_ status: FirewallEvent.Status) async throws -> [FirewallEventDTO] {
        return try await actor.fetchByStatus(status)
    }
    
    /// 根据时间范围查找FirewallEvent记录
    /// - Parameters:
    ///   - startDate: 开始时间
    ///   - endDate: 结束时间
    /// - Returns: 指定时间范围内的所有FirewallEventDTO记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchByTimeRange(from startDate: Date, to endDate: Date) async throws -> [FirewallEventDTO] {
        os_log("\(self.t) fetchByTimeRange: \(startDate) - \(endDate)")
        return try await actor.fetchByTimeRange(from: startDate, to: endDate)
    }
    
    /// 复合查询：根据应用ID和状态查找记录
    /// - Parameters:
    ///   - appId: 应用程序ID
    ///   - status: 防火墙状态
    /// - Returns: 符合条件的FirewallEventDTO记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchByAppIdAndStatus(_ appId: String, status: FirewallEvent.Status) async throws -> [FirewallEventDTO] {
        return try await actor.fetchByAppIdAndStatus(appId, status: status)
    }

    // MARK: - Statistics

    /// 获取事件总数
    /// - Returns: 事件总数
    /// - Throws: 查询数据时可能抛出的错误
    func getEventCount() async throws -> Int {
        os_log("\(self.t) getEventCount")
        return try await actor.getEventCount()
    }

    /// 获取指定应用的事件总数
    /// - Parameter appId: 应用程序ID
    /// - Returns: 该应用的事件总数
    /// - Throws: 查询数据时可能抛出的错误
    func getEventCountByAppId(_ appId: String) async throws -> Int {
        os_log("\(self.t) getEventCountByAppId: \(appId)")
        return try await actor.getEventCountByAppId(appId)
    }

    /// 获取指定应用的事件总数（带筛选）
    /// - Parameters:
    ///   - appId: 应用程序ID
    ///   - statusFilter: 状态筛选（可选）
    ///   - directionFilter: 方向筛选（可选）
    /// - Returns: 符合条件的事件总数
    /// - Throws: 查询数据时可能抛出的错误
    func getEventCountByAppIdFiltered(
        _ appId: String,
        statusFilter: FirewallEvent.Status? = nil,
        directionFilter: NETrafficDirection? = nil
    ) async throws -> Int {
        os_log("\(self.t) getEventCountByAppIdFiltered: \(appId)")
        return try await actor.getEventCountByAppIdFiltered(appId, statusFilter: statusFilter, directionFilter: directionFilter)
    }

    /// 获取被阻止的事件总数
    /// - Returns: 被阻止的事件总数
    /// - Throws: 查询数据时可能抛出的错误
    func getRejectedEventCount() async throws -> Int {
        os_log("\(self.t) getRejectedEventCount")
        return try await actor.getRejectedEventCount()
    }

    /// 获取被允许的事件总数
    /// - Returns: 被允许的事件总数
    /// - Throws: 查询数据时可能抛出的错误
    func getAllowedEventCount() async throws -> Int {
        os_log("\(self.t) getAllowedEventCount")
        return try await actor.getAllowedEventCount()
    }
    
    /// 分页获取所有FirewallEvent记录
    /// - Parameters:
    ///   - page: 页码（从0开始）
    ///   - pageSize: 每页记录数
    /// - Returns: 分页后的FirewallEventDTO记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchAllPaginated(
        page: Int,
        pageSize: Int
    ) async throws -> [FirewallEventDTO] {
        os_log("\(self.t) fetchAllPaginated, page: \(page), pageSize: \(pageSize)")
        return try await actor.fetchAllPaginated(page: page, pageSize: pageSize)
    }
    
    /// 获取所有应用ID列表
    /// - Returns: 所有唯一的应用ID数组
    /// - Throws: 查询数据时可能抛出的错误
    func getAllAppIds() async throws -> [String] {
        os_log("\(self.t) getAllAppIds")
        return try await actor.getAllAppIds()
    }
    
    /// 根据应用ID分页查找FirewallEvent记录
    /// - Parameters:
    ///   - appId: 应用程序ID
    ///   - page: 页码（从0开始）
    ///   - pageSize: 每页记录数
    ///   - statusFilter: 状态筛选（可选）
    ///   - directionFilter: 方向筛选（可选）
    /// - Returns: 分页后的FirewallEventDTO记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchByAppIdPaginated(
        _ appId: String,
        page: Int,
        pageSize: Int,
        statusFilter: FirewallEvent.Status? = nil,
        directionFilter: NETrafficDirection? = nil
    ) async throws -> [FirewallEventDTO] {
        os_log("\(self.t) fetchByAppIdPaginated: \(appId), page: \(page), pageSize: \(pageSize)")
        return try await actor.fetchByAppIdPaginated(appId, page: page, pageSize: pageSize, statusFilter: statusFilter, directionFilter: directionFilter)
    }
}

// MARK: - Event Emission

extension EventRepo {
    /// 发送新事件创建通知
    /// - Parameter event: 新创建的事件
    func emitEventCreated(_ event: FirewallEventModel) {
        NotificationCenter.default.post(name: .firewallEventCreated, object: nil, userInfo: [
            "event": event,
        ])
    }

    /// 发送事件删除通知
    /// - Parameter eventId: 被删除的事件ID
    func emitEventDeleted(_ eventId: String) {
        NotificationCenter.default.post(name: .firewallEventDeleted, object: nil, userInfo: [
            "eventId": eventId,
        ])
    }
}

// MARK: - Async Convenience APIs

extension EventRepo {
    /// 后台分页查询，并在主线程返回结果
    /// - Parameters:
    ///   - appId: 应用ID
    ///   - page: 页码（从0开始）
    ///   - pageSize: 每页数量
    ///   - statusFilter: 状态筛选
    ///   - directionFilter: 方向筛选
    ///   - completion: 主线程回调 (totalCount, events)
    func fetchByAppIdPaginatedAsync(
        _ appId: String,
        page: Int,
        pageSize: Int,
        statusFilter: FirewallEvent.Status? = nil,
        directionFilter: NETrafficDirection? = nil,
        completion: @escaping @MainActor (Int, [FirewallEventDTO]) -> Void
    ) {
        let queryActor = self.actor
        Task.detached(priority: .utility) {
            let totalCount: Int
            let events: [FirewallEventDTO]
            do {
                let count = try await queryActor.getEventCountByAppIdFiltered(appId, statusFilter: statusFilter, directionFilter: directionFilter)
                let list = try await queryActor.fetchByAppIdPaginated(appId, page: page, pageSize: pageSize, statusFilter: statusFilter, directionFilter: directionFilter)
                totalCount = count
                events = list
            } catch {
                totalCount = 0
                events = []
            }

            await MainActor.run {
                completion(totalCount, events)
            }
        }
    }
    
    /// 后台获取所有应用ID列表，并在主线程回调
    /// - Parameter completion: 主线程回调，返回应用ID数组
    func getAllAppIdsAsync(completion: @escaping @MainActor ([String]) -> Void) {
        let queryActor = self.actor
        Task.detached(priority: .utility) {
            let appIds: [String]
            do {
                appIds = try await queryActor.getAllAppIds()
            } catch {
                appIds = []
            }
            
            await MainActor.run {
                completion(appIds)
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
        // 组合查询谓词
        var predicates: [Predicate<FirewallEventModel>] = [
            #Predicate<FirewallEventModel> { item in item.sourceAppIdentifier == appId },
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

    // MARK: - CRUD Operations

    /// 创建新的FirewallEvent记录
    func create(_ event: FirewallEvent) throws {
        os_log("\(self.t) create event: \(event.id)")
        let eventModel = FirewallEventModel.from(event)
        modelContext.insert(eventModel)
        try modelContext.save()
    }

    /// 删除指定应用的所有事件记录
    func deleteByAppId(_ appId: String) throws {
        os_log("\(self.t) deleteByAppId: \(appId)")
        let predicate = #Predicate<FirewallEventModel> { item in
            item.sourceAppIdentifier == appId
        }

        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        let events = try modelContext.fetch(descriptor)
        for event in events {
            modelContext.delete(event)
        }
        try modelContext.save()
    }

    /// 删除指定应用ID超过指定天数的事件记录
    func deleteOldEventsByAppId(_ appId: String, olderThanDays days: Int) throws -> Int {
        os_log("\(self.t) deleteOldEventsByAppId: \(appId), days: \(days)")
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let predicate = #Predicate<FirewallEventModel> { item in
            item.sourceAppIdentifier == appId && item.time < cutoffDate
        }

        let events = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        let deletedCount = events.count

        for event in events {
            modelContext.delete(event)
        }

        if deletedCount > 0 {
            try modelContext.save()
            os_log("\(self.t)已删除应用 \(appId) 超过 \(days) 天的 \(deletedCount) 条事件记录")
        }

        return deletedCount
    }

    /// 批量清理所有应用超过指定天数的事件记录
    func cleanupOldEvents(olderThanDays days: Int) throws -> Int {
        os_log("\(self.t) cleanupOldEvents, days: \(days)")
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let predicate = #Predicate<FirewallEventModel> { item in
            item.time < cutoffDate
        }

        let events = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        let deletedCount = events.count

        for event in events {
            modelContext.delete(event)
        }

        if deletedCount > 0 {
            try modelContext.save()
            os_log("\(self.t)🧹 已清理超过 \(days) 天的 \(deletedCount) 条事件记录")
        }

        return deletedCount
    }

    // MARK: - Query Operations

    /// 根据应用ID查找FirewallEvent记录
    func fetchByAppId(_ appId: String) throws -> [FirewallEventDTO] {
        os_log("\(self.t) fetchByAppId: \(appId)")
        let predicate = #Predicate<FirewallEventModel> { item in
            item.sourceAppIdentifier == appId
        }

        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        let models = try modelContext.fetch(descriptor)
        return models.map(FirewallEventDTO.fromModel)
    }
    
    /// 根据状态查找FirewallEvent记录
    func fetchByStatus(_ status: FirewallEvent.Status) throws -> [FirewallEventDTO] {
        let statusValue = status == .allowed ? 0 : 1
        let predicate = #Predicate<FirewallEventModel> { item in
            item.statusRawValue == statusValue
        }

        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        let models = try modelContext.fetch(descriptor)
        return models.map(FirewallEventDTO.fromModel)
    }
    
    /// 根据时间范围查找FirewallEvent记录
    func fetchByTimeRange(from startDate: Date, to endDate: Date) throws -> [FirewallEventDTO] {
        os_log("\(self.t) fetchByTimeRange: \(startDate) - \(endDate)")
        let predicate = #Predicate<FirewallEventModel> { item in
            item.time >= startDate && item.time <= endDate
        }

        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        let models = try modelContext.fetch(descriptor)
        return models.map(FirewallEventDTO.fromModel)
    }
    
    /// 复合查询：根据应用ID和状态查找记录
    func fetchByAppIdAndStatus(_ appId: String, status: FirewallEvent.Status) throws -> [FirewallEventDTO] {
        let statusValue = status == .allowed ? 0 : 1
        let predicate = #Predicate<FirewallEventModel> { item in
            item.sourceAppIdentifier == appId && item.statusRawValue == statusValue
        }

        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )
        let models = try modelContext.fetch(descriptor)
        return models.map(FirewallEventDTO.fromModel)
    }

    // MARK: - Statistics

    /// 获取事件总数
    func getEventCount() throws -> Int {
        os_log("\(self.t) getEventCount")
        let descriptor = FetchDescriptor<FirewallEventModel>()
        return try modelContext.fetchCount(descriptor)
    }

    /// 获取指定应用的事件总数
    func getEventCountByAppId(_ appId: String) throws -> Int {
        os_log("\(self.t) getEventCountByAppId: \(appId)")
        let predicate = #Predicate<FirewallEventModel> { item in
            item.sourceAppIdentifier == appId
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }

    /// 获取指定应用的事件总数（带筛选）
    func getEventCountByAppIdFiltered(
        _ appId: String,
        statusFilter: FirewallEvent.Status? = nil,
        directionFilter: NETrafficDirection? = nil
    ) throws -> Int {
        os_log("\(self.t) getEventCountByAppIdFiltered: \(appId)")
        // 构建查询条件
        var predicates: [Predicate<FirewallEventModel>] = [
            #Predicate<FirewallEventModel> { item in item.sourceAppIdentifier == appId },
        ]

        // 添加状态筛选
        if let statusFilter = statusFilter {
            let statusValue = statusFilter == .allowed ? 0 : 1
            predicates.append(#Predicate<FirewallEventModel> { item in item.statusRawValue == statusValue })
        }

        // 添加方向筛选
        if let directionFilter = directionFilter {
            let directionValue = directionFilter.rawValue
            predicates.append(#Predicate<FirewallEventModel> { item in item.directionRawValue == directionValue })
        }

        // 组合所有条件
        let combinedPredicate = predicates.reduce(into: predicates[0]) { result, predicate in
            result = #Predicate<FirewallEventModel> { item in
                result.evaluate(item) && predicate.evaluate(item)
            }
        }

        let descriptor = FetchDescriptor(predicate: combinedPredicate)
        return try modelContext.fetchCount(descriptor)
    }

    /// 获取被阻止的事件总数
    func getRejectedEventCount() throws -> Int {
        os_log("\(self.t) getRejectedEventCount")
        let predicate = #Predicate<FirewallEventModel> { item in
            item.statusRawValue == 1
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }

    /// 获取被允许的事件总数
    func getAllowedEventCount() throws -> Int {
        os_log("\(self.t) getAllowedEventCount")
        let predicate = #Predicate<FirewallEventModel> { item in
            item.statusRawValue == 0
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }

    /// 根据应用ID分页查找FirewallEvent记录
    func fetchByAppIdPaginated(
        _ appId: String,
        page: Int,
        pageSize: Int,
        statusFilter: FirewallEvent.Status? = nil,
        directionFilter: NETrafficDirection? = nil
    ) throws -> [FirewallEventDTO] {
        os_log("\(self.t) fetchByAppIdPaginated: \(appId), page: \(page), pageSize: \(pageSize)")

        // 构建查询条件
        var predicates: [Predicate<FirewallEventModel>] = [
            #Predicate<FirewallEventModel> { item in item.sourceAppIdentifier == appId },
        ]

        // 添加状态筛选
        if let statusFilter = statusFilter {
            let statusValue = statusFilter == .allowed ? 0 : 1
            predicates.append(#Predicate<FirewallEventModel> { item in item.statusRawValue == statusValue })
        }

        // 添加方向筛选
        if let directionFilter = directionFilter {
            let directionValue = directionFilter.rawValue
            predicates.append(#Predicate<FirewallEventModel> { item in item.directionRawValue == directionValue })
        }

        // 组合所有条件
        let combinedPredicate = predicates.reduce(into: predicates[0]) { result, predicate in
            result = #Predicate<FirewallEventModel> { item in
                result.evaluate(item) && predicate.evaluate(item)
            }
        }

        // 创建查询描述符
        var descriptor = FetchDescriptor<FirewallEventModel>(
            predicate: combinedPredicate,
            sortBy: [SortDescriptor(\FirewallEventModel.time, order: .reverse)]
        )

        // 设置分页参数
        descriptor.fetchOffset = page * pageSize
        descriptor.fetchLimit = pageSize

        let models = try modelContext.fetch(descriptor)
        return models.map(FirewallEventDTO.fromModel)
    }
    
    /// 分页获取所有FirewallEvent记录
    func fetchAllPaginated(
        page: Int,
        pageSize: Int
    ) throws -> [FirewallEventDTO] {
        os_log("\(self.t) fetchAllPaginated, page: \(page), pageSize: \(pageSize)")
        
        // 创建查询描述符
        var descriptor = FetchDescriptor<FirewallEventModel>(
            sortBy: [SortDescriptor(\.time, order: .reverse)]
        )
        
        // 设置分页参数
        descriptor.fetchOffset = page * pageSize
        descriptor.fetchLimit = pageSize
        
        let models = try modelContext.fetch(descriptor)
        return models.map(FirewallEventDTO.fromModel)
    }
    
    /// 获取所有唯一的应用ID列表
    func getAllAppIds() throws -> [String] {
        os_log("\(self.t) getAllAppIds")
        
        // 创建查询描述符，只获取 sourceAppIdentifier 字段
        let descriptor = FetchDescriptor<FirewallEventModel>(
            sortBy: [SortDescriptor(\.sourceAppIdentifier, order: .forward)]
        )
        
        // 获取所有记录
        let models = try modelContext.fetch(descriptor)
        
        // 提取唯一的应用ID并去重
        let uniqueAppIds = Set(models.map { $0.sourceAppIdentifier })
        
        // 转换为数组并排序
        return Array(uniqueAppIds).sorted()
    }
}

/// 结果传输对象：跨并发边界传递，声明为 @unchecked Sendable 以放宽检查
struct EventPageResult: Sendable {
    let totalCount: Int
    let events: [FirewallEventDTO]
}

// MARK: - Notification Names

extension Notification.Name {
    static let firewallEventCreated = Notification.Name("firewallEventCreated")
    static let firewallEventDeleted = Notification.Name("firewallEventDeleted")
}

// MARK: - Preview

#Preview("App - Large") {
    ContentView()
        .inRootView()
        .frame(width: 600, height: 1000)
}

#Preview("App - Small") {
    ContentView()
        .inRootView()
        .frame(width: 600, height: 600)
}

#if os(iOS)
    #Preview("iPhone") {
        AppPreview()
    }
#endif
