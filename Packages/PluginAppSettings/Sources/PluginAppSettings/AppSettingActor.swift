import Foundation
import PluginPersistence
import ProviderAppSettings
import SwiftData

/// 串行执行 SwiftData 查询的 actor（对应旧 `AppSettingQueryActor` 语义）。
///
/// 线程/actor：`ModelActor`，内部串行访问 modelContext；只暴露中立 Snapshot。
actor AppSettingActor: ModelActor {
    let modelContainer: ModelContainer
    nonisolated let modelExecutor: ModelExecutor

    init(container: ModelContainer) {
        self.modelContainer = container
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: ModelContext(container))
    }

    /// 创建或更新规则（旧 `updateAllowedStatus`：存在则更新，否则创建）。
    func upsert(id: String, allowed: Bool) throws {
        let predicate = #Predicate<AppSetting> { item in
            item.appId == id
        }
        let items = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        if let setting = items.first {
            setting.allowed = allowed
        } else {
            modelContext.insert(AppSetting(appId: id, allowed: allowed))
        }
        try modelContext.save()
    }

    /// 删除规则；不存在则静默成功。
    func delete(id: String) throws {
        let predicate = #Predicate<AppSetting> { item in
            item.appId == id
        }
        let items = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        if let setting = items.first {
            modelContext.delete(setting)
            try modelContext.save()
        }
    }

    /// 单条规则。
    func find(id: String) throws -> AppSettingSnapshot? {
        let predicate = #Predicate<AppSetting> { item in
            item.appId == id
        }
        let items = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        return items.first.map { AppSettingSnapshot(appId: $0.appId, allowed: $0.allowed) }
    }

    /// 全部规则。
    func fetchAll() throws -> [AppSettingSnapshot] {
        let models = try modelContext.fetch(FetchDescriptor<AppSetting>())
        return models.map { AppSettingSnapshot(appId: $0.appId, allowed: $0.allowed) }
    }

    /// 被拒绝的规则。
    func fetchDenied() throws -> [AppSettingSnapshot] {
        let predicate = #Predicate<AppSetting> { item in
            item.allowed == false
        }
        let models = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        return models.map { AppSettingSnapshot(appId: $0.appId, allowed: $0.allowed) }
    }
}
