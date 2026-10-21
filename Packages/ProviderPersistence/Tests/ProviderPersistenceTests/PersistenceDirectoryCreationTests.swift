import Foundation
import Testing
@testable import ProviderPersistence

/// 数据库目录按需创建契约的测试。
///
/// `PersistenceConfig.getDatabaseURL()` 的契约：数据库目录不存在则创建，
/// 创建失败则 `fatalError`（启动期配置错误，与旧实现一致）。
///
/// 说明：单元测试进程运行在 App 沙箱里，`~/Documents` 映射到 App 容器目录，
/// 该目录受 macOS TCC 保护——可以创建，但无法枚举/删除既有内容，
/// 因此单测无法主动删掉数据库目录来强制走「创建」分支。
/// 本用例按「目录是否存在」自适应：目录尚不存在时（全新机器 / CI）
/// 读取 `databaseURL` 即会走通创建分支；目录已存在时校验幂等契约。
@MainActor
@Suite("PersistenceConfig 目录创建")
struct PersistenceDirectoryCreationTests {

    @Test("读取 databaseURL 会确保数据库目录存在（不存在则创建）")
    func databaseURLEnsuresDirectoryExists() {
        let folder = PersistenceConfig.databaseFolder
        let existedBefore = FileManager.default.fileExists(atPath: folder.path)

        let url = PersistenceConfig.databaseURL

        // 契约：无论目录此前是否存在，读取之后目录必定存在。
        #expect(FileManager.default.fileExists(atPath: folder.path))
        #expect(url.deletingLastPathComponent() == folder)
        #expect(url.lastPathComponent == PersistenceConfig.dbFileName)
        // 重复读取幂等。
        #expect(PersistenceConfig.databaseURL == url)
        // 目录此前不存在时，本次读取应当已经把它创建出来。
        #expect(existedBefore || FileManager.default.fileExists(atPath: folder.path))
    }

    @Test("databaseFolder 与 databaseURL 指向同一个目录")
    func folderAndURLAgree() {
        let folder = PersistenceConfig.databaseFolder
        let url = PersistenceConfig.databaseURL

        #expect(folder == url.deletingLastPathComponent())
        #expect(folder.path.hasSuffix(PersistenceConfig.databaseFolder.lastPathComponent))
    }
}
