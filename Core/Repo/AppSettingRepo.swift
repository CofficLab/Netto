/*
 说明：为何同时存在 AppSettingRepo（class）与 AppSettingQueryActor（actor）

 - 分层动机：
   - AppSettingQueryActor（符合 SwiftData 的 ModelActor）：
     作为数据访问边界，内部使用 modelContext 串行执行查询，确保并发安全与线程正确性；
     不直接暴露给 SwiftUI 作为环境对象使用。

   - AppSettingRepo（ObservableObject/class）：
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
import OSLog
import SwiftData
import SwiftUI

/// 基于 actor 的仓库
final class AppSettingRepo: ObservableObject, SuperLog, SuperEvent {
    private let actor: AppSettingQueryActor
    private let container: ModelContainer

    /// 使用自定义 ModelContainer 初始化
    init(container: ModelContainer) {
        self.container = container
        self.actor = AppSettingQueryActor(container: container)
    }

    /// 使用默认容器初始化
    convenience init() {
        self.init(container: TavelMode.container())
    }

    // MARK: - CRUD Operations

    /// 创建新的AppSetting记录
    /// - Parameters:
    ///   - id: 应用程序ID
    ///   - allowed: 是否允许访问，默认为true
    /// - Throws: 保存数据时可能抛出的错误
    func create(_ id: String, allowed: Bool = true) async throws {
        os_log("\(self.t) create appId: \(id), allowed: \(allowed)")
        try await actor.create(id, allowed: allowed)
    }

    /// 根据ID查找AppSetting记录
    /// - Parameter id: 应用程序ID
    /// - Returns: 找到的AppSettingDTO实例，如果未找到则返回nil
    /// - Throws: 查询数据时可能抛出的错误
    func find(_ id: String) async throws -> AppSettingDTO? {
        os_log("\(self.t) find appId: \(id)")
        return try await actor.findDTO(id)
    }

    /// 更新AppSetting记录的允许状态
    /// - Parameters:
    ///   - id: 应用程序ID
    ///   - allowed: 新的允许状态
    /// - Throws: 保存数据时可能抛出的错误
    func updateAllowedStatus(_ id: String, allowed: Bool) async throws {
        os_log("\(self.t) updateAllowedStatus appId: \(id), allowed: \(allowed)")
        try await actor.updateAllowedStatus(id, allowed: allowed)
    }

    /// 删除AppSetting记录
    /// - Parameter id: 应用程序ID
    /// - Throws: 删除数据时可能抛出的错误
    func delete(_ id: String) async throws {
        os_log("\(self.t) delete appId: \(id)")
        try await actor.delete(id)
    }

    /// 获取所有AppSetting记录
    /// - Returns: 所有AppSettingDTO记录的数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchAll() async throws -> [AppSettingDTO] {
        os_log("\(self.t) fetchAll")
        return try await actor.fetchAllDTO()
    }

    /// 获取所有被拒绝访问的AppSetting记录
    /// - Returns: 所有allowed为false的AppSettingDTO记录数组
    /// - Throws: 查询数据时可能抛出的错误
    func fetchDeniedApps() async throws -> [AppSettingDTO] {
        os_log("\(self.t) fetchDeniedApps")
        return try await actor.fetchDeniedAppsDTO()
    }


    // MARK: - Permission Management

    /// 检查指定ID的应用是否应该被允许访问网络（异步版本）
    /// - Parameter id: 应用程序或进程ID
    /// - Returns: 如果允许访问返回true，否则返回false
    func shouldAllow(_ id: String) async -> Bool {
        do {
            if let setting = try await find(id) {
                return setting.allowed
            } else {
                return true
            }
        } catch {
            os_log("Error checking permission for \(id): \(error.localizedDescription)")
            return true // 默认允许
        }
    }

    /// 检查指定ID的应用是否应该被允许访问网络（同步版本）
    /// - Parameter id: 应用程序或进程ID
    /// - Returns: 如果允许访问返回true，否则返回false
    func shouldAllowSync(_ id: String) -> Bool {
        do {
            // 直接使用 ModelContainer 进行同步查询
            let context = ModelContext(container)
            let predicate = #Predicate<AppSetting> { item in
                item.appId == id
            }
            
            let items = try context.fetch(FetchDescriptor(predicate: predicate))
            if let setting = items.first {
                os_log("\(self.t) shouldAllowSync for \(id) - found setting: \(setting.allowed)")
                return setting.allowed
            } else {
                os_log("\(self.t) shouldAllowSync for \(id) - no setting found, defaulting to true")
                return true
            }
        } catch {
            os_log("Error checking permission for \(id): \(error.localizedDescription)")
            return true // 默认允许
        }
    }

    /// 设置指定ID的应用为拒绝访问
    /// - Parameter id: 应用程序ID
    /// - Throws: 保存数据时可能抛出的错误
    func setDeny(_ id: String) async throws {
        try await updateAllowedStatus(id, allowed: false)
        self.emitDidSetDeny(id)
    }

    /// 设置指定ID的应用为允许访问
    /// - Parameter id: 应用程序ID
    /// - Throws: 保存数据时可能抛出的错误
    func setAllow(_ id: String) async throws {
        try await updateAllowedStatus(id, allowed: true)
        self.emitDidSetAllow(id)
    }
}

// MARK: - Async Convenience APIs

extension AppSettingRepo {
    /// 后台查询并在主线程回调
    func findAsync(
        _ id: String,
        completion: @escaping @MainActor @Sendable (AppSettingDTO?) -> Void
    ) {
        let queryActor = self.actor
        Task.detached(priority: .utility) {
            let result: AppSettingDTO?
            do {
                result = try await queryActor.findDTO(id)
            } catch {
                result = nil
            }
            await MainActor.run {
                completion(result)
            }
        }
    }

    /// 后台获取所有记录并在主线程回调
    func fetchAllAsync(
        completion: @escaping @MainActor @Sendable ([AppSettingDTO]) -> Void
    ) {
        let queryActor = self.actor
        Task.detached(priority: .utility) {
            let result: [AppSettingDTO]
            do {
                result = try await queryActor.fetchAllDTO()
            } catch {
                result = []
            }
            await MainActor.run {
                completion(result)
            }
        }
    }

    /// 后台获取被拒绝的应用并在主线程回调
    func fetchDeniedAppsAsync(
        completion: @escaping @MainActor @Sendable ([AppSettingDTO]) -> Void
    ) {
        let queryActor = self.actor
        Task.detached(priority: .utility) {
            let result: [AppSettingDTO]
            do {
                result = try await queryActor.fetchDeniedAppsDTO()
            } catch {
                result = []
            }
            await MainActor.run {
                completion(result)
            }
        }
    }

}

// MARK: - Event Emission

extension AppSettingRepo {
    /// 发送允许访问事件通知
    /// - Parameter appId: 应用程序ID
    func emitDidSetAllow(_ appId: String) {
        emit(name: .didSetAllow, object: nil, userInfo: [
            "appId": appId,
        ])
    }

    /// 发送拒绝访问事件通知
    /// - Parameter appId: 应用程序ID
    func emitDidSetDeny(_ appId: String) {
        emit(name: .didSetDeny, object: nil, userInfo: [
            "appId": appId,
        ])
    }
}

/// 串行执行 SwiftData 查询的 actor（对外隐藏实现细节）
private actor AppSettingQueryActor: ModelActor, SuperLog {
    let modelContainer: ModelContainer
    nonisolated let modelExecutor: ModelExecutor

    init(container: ModelContainer) {
        self.modelContainer = container
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: ModelContext(container))
    }

    // MARK: - CRUD Operations

    /// 创建新的AppSetting记录
    func create(_ id: String, allowed: Bool = true) throws {
        os_log("\(self.t) create appId: \(id), allowed: \(allowed)")
        let appSetting = AppSetting(appId: id, allowed: allowed)
        modelContext.insert(appSetting)
        try modelContext.save()
    }


    /// 更新AppSetting记录的允许状态
    func updateAllowedStatus(_ id: String, allowed: Bool) throws {
        os_log("\(self.t) updateAllowedStatus appId: \(id), allowed: \(allowed)")
        let predicate = #Predicate<AppSetting> { item in
            item.appId == id
        }
        
        let items = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        if let setting = items.first {
            setting.allowed = allowed
        } else {
            try create(id, allowed: allowed)
        }

        try modelContext.save()
    }

    /// 删除AppSetting记录
    func delete(_ id: String) throws {
        os_log("\(self.t) delete appId: \(id)")
        let predicate = #Predicate<AppSetting> { item in
            item.appId == id
        }
        
        let items = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        if let setting = items.first {
            modelContext.delete(setting)
            try modelContext.save()
        }
    }


    // MARK: - DTO Operations

    /// 根据ID查找AppSetting记录（返回DTO）
    func findDTO(_ id: String) throws -> AppSettingDTO? {
        os_log("\(self.t) findDTO appId: \(id)")
        let predicate = #Predicate<AppSetting> { item in
            item.appId == id
        }

        let items = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        return items.first.map(AppSettingDTO.fromModel)
    }

    /// 获取所有AppSetting记录（返回DTO）
    func fetchAllDTO() throws -> [AppSettingDTO] {
        os_log("\(self.t) fetchAllDTO")
        let models = try modelContext.fetch(FetchDescriptor<AppSetting>())
        return models.map(AppSettingDTO.fromModel)
    }

    /// 获取所有被拒绝访问的AppSetting记录（返回DTO）
    func fetchDeniedAppsDTO() throws -> [AppSettingDTO] {
        os_log("\(self.t) fetchDeniedAppsDTO")
        let predicate = #Predicate<AppSetting> { item in
            item.allowed == false
        }

        let models = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        return models.map(AppSettingDTO.fromModel)
    }
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
