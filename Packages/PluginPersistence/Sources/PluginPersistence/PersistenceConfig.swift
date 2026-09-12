import Foundation

/// 持久化配置 —— 与旧 `AppConfig` 的数据库目录规则**逐字一致**。
///
/// 兼容红线：文件名 `db.sqlite`、`~/Documents/debug|production` 目录、Debug 分支
/// 取 `debug`、Release 取 `production`，均不得改变。
@MainActor
public enum PersistenceConfig {
    nonisolated static let dbFileName = "db.sqlite"
    nonisolated static let label = "com.yueyi.TravelMode"
    nonisolated static let appName = "TravelMode"

    /// 用户文档目录。
    nonisolated static var documentsURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
    }

    /// 数据库目录（`~/Documents/debug` 或 `~/Documents/production`）。
    nonisolated static var databaseFolder: URL {
        databaseURL.deletingLastPathComponent()
    }

    /// 数据库文件 URL（`~/Documents/debug|production/db.sqlite`）。
    nonisolated static var databaseURL: URL {
        getDatabaseURL()
    }

    /// 与旧 `AppConfig.getDatabaseURL()` 相同：目录不存在则创建（失败即终止启动，
    /// 与旧行为 fatalError 语义一致）。
    nonisolated private static func getDatabaseURL() -> URL {
        let fileName = dbFileName
        #if DEBUG
            let dirName = "debug"
        #else
            let dirName = "production"
        #endif

        var isDir: ObjCBool = true
        let dbDir = documentsURL
            .appendingPathComponent(dirName, isDirectory: true)

        if !FileManager.default.fileExists(atPath: dbDir.path, isDirectory: &isDir) {
            do {
                try FileManager.default.createDirectory(
                    atPath: dbDir.path,
                    withIntermediateDirectories: true
                )
            } catch let error {
                fatalError("新建数据库文件夹发生错误：\(error.localizedDescription)")
            }
        }

        return dbDir.appendingPathComponent(fileName)
    }
}
