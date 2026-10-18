import Foundation
import Testing
@testable import ProviderPersistence

/// `PersistenceConfig` 目录规则测试。
///
/// 兼容红线：数据库文件名、Documents 子目录名（Debug=debug / Release=production）
/// 必须与旧 `AppConfig` 逐字一致，改动会让用户既有数据「失联」，故以测试锁定。
@MainActor
@Suite("PersistenceConfig")
struct PersistenceConfigTests {

    @Test("数据库文件名与标签为兼容红线常量")
    func stableConstants() {
        #expect(PersistenceConfig.dbFileName == "db.sqlite")
        #expect(PersistenceConfig.label == "com.yueyi.TravelMode")
        #expect(PersistenceConfig.appName == "TravelMode")
    }

    @Test("documentsURL 指向用户 Documents 目录")
    func documentsURL() {
        let expected = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
        #expect(PersistenceConfig.documentsURL == expected)
    }

    @Test("数据库目录为 Documents 下与构建配置匹配的子目录")
    func databaseFolderMatchesBuildConfiguration() {
        let expectedName: String = {
            #if DEBUG
            return "debug"
            #else
            return "production"
            #endif
        }()

        let folder = PersistenceConfig.databaseFolder
        #expect(folder.lastPathComponent == expectedName)
        #expect(folder.deletingLastPathComponent() == PersistenceConfig.documentsURL)
    }

    @Test("数据库 URL 为目录下的 db.sqlite")
    func databaseURLLayout() {
        let url = PersistenceConfig.databaseURL
        #expect(url.lastPathComponent == PersistenceConfig.dbFileName)
        #expect(url.deletingLastPathComponent() == PersistenceConfig.databaseFolder)
    }

    @Test("访问 databaseURL 会确保数据库目录已存在")
    func databaseFolderIsCreatedOnDemand() {
        // getDatabaseURL 的契约：目录不存在则创建。
        let folder = PersistenceConfig.databaseFolder
        #expect(
            FileManager.default.fileExists(atPath: folder.path, isDirectory: nil),
            "读取 databaseURL 后数据库目录应已存在"
        )
    }

    @Test("databaseFolder 与 databaseURL 读取一致（重复调用幂等）")
    func repeatedReadsAreStable() {
        let first = PersistenceConfig.databaseURL
        let second = PersistenceConfig.databaseURL
        #expect(first == second)
        #expect(PersistenceConfig.databaseFolder == first.deletingLastPathComponent())
    }
}
