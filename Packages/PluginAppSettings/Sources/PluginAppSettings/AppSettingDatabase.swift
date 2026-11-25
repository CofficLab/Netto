import Foundation
import ProviderAppSettings
import ProviderPersistence
import SwiftData

/// 规则库数据层：全部 SwiftData 读写都在专用串行队列上执行。
final class AppSettingDatabase: Sendable {
    private let database: SerialModelDatabase

    init(container: ModelContainer) {
        self.database = SerialModelDatabase(
            container: container,
            label: "com.yueyi.TravelMode.appsettings.database"
        )
    }

    func fetchAll() async throws -> [AppSettingSnapshot] {
        try await database.perform { context in
            try context.fetch(FetchDescriptor<AppSetting>())
                .map { AppSettingSnapshot(appId: $0.appId, allowed: $0.allowed) }
        }
    }

    func upsert(id: String, allowed: Bool) async throws {
        try await database.perform { context in
            let predicate = #Predicate<AppSetting> { item in
                item.appId == id
            }
            let items = try context.fetch(FetchDescriptor(predicate: predicate))
            if let setting = items.first {
                setting.allowed = allowed
            } else {
                context.insert(AppSetting(appId: id, allowed: allowed))
            }
            try context.save()
        }
    }

    func delete(id: String) async throws {
        try await database.perform { context in
            let predicate = #Predicate<AppSetting> { item in
                item.appId == id
            }
            try context.delete(model: AppSetting.self, where: predicate)
            try context.save()
        }
    }
}