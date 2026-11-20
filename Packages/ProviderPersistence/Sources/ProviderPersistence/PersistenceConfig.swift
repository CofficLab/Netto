import Foundation

/// 持久化路径规则 —— 与 Lumi 的插件存储规范一致。
///
/// 数据根目录：`~/Library/Application Support/<bundleID>/db_<debug|production>_v<主版本>/`，
/// 每个数据插件的库文件放在自己的插件目录下（目录名 = pluginID）。
/// 运行期路径必须经 `StorageProviding` 获取；这里只保留目录名、文件名与旧版库位置。
@MainActor
public enum PersistenceConfig {
    nonisolated public static let eventsPluginID = "eventstore"
    nonisolated public static let settingsPluginID = "appsettings"
    nonisolated public static let eventsFileName = "events.sqlite"
    nonisolated public static let settingsFileName = "settings.sqlite"

    nonisolated static let label = "com.yueyi.TravelMode"
    public nonisolated static let appName = "TravelMode"

    /// v3 之前的唯一数据库：`~/Documents/debug|production/db.sqlite`。
    ///
    /// 只用于启动时的一次性复制迁移；迁移完成后旧库保留不删除。
    public nonisolated static var legacyDatabaseURL: URL {
        legacyDatabaseURL(baseDocumentsURL: documentsURL)
    }

    nonisolated static var documentsURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
    }

    nonisolated static func legacyDatabaseURL(baseDocumentsURL: URL) -> URL {
        #if DEBUG
        let dirName = "debug"
        #else
        let dirName = "production"
        #endif

        return baseDocumentsURL
            .appendingPathComponent(dirName, isDirectory: true)
            .appendingPathComponent("db.sqlite")
    }
}
