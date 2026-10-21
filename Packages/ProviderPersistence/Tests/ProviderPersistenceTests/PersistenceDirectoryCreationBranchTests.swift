import Foundation
import Testing
@testable import ProviderPersistence

/// 数据库目录「按需创建」分支的测试。
///
/// ## 可达性说明
/// 生产路径的 Documents 目录（`~/Documents`）受 macOS TCC 保护，
/// 单测既无法清空它、也无法可靠地制造「目录不存在」的状态，
/// 因此 `getDatabaseURL` 里的创建分支在既有测试中始终未被执行。
/// 生产实现已把 Documents 根目录抽为 `getDatabaseURL(baseDocumentsURL:)` 入参
/// （生产入口仍传 `PersistenceConfig.documentsURL`），
/// 本文件用临时目录精确驱动该分支。
@MainActor
@Suite("PersistenceConfig 目录创建分支")
struct PersistenceDirectoryCreationBranchTests {

    /// 与构建配置匹配的数据库目录名（Debug=debug / Release=production）。
    private var expectedDirectoryName: String {
        #if DEBUG
        return "debug"
        #else
        return "production"
        #endif
    }

    /// 构造一个空的临时 Documents 根目录。
    private func makeTemporaryDocumentsRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("NettoPersistenceTest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    @Test("数据库目录不存在时按需创建")
    func createsDatabaseFolderOnDemand() throws {
        let root = try makeTemporaryDocumentsRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let url = PersistenceConfig.getDatabaseURL(baseDocumentsURL: root)
        let folder = url.deletingLastPathComponent()

        #expect(FileManager.default.fileExists(atPath: folder.path), "读取后数据库目录应已存在")
        #expect(folder.lastPathComponent == expectedDirectoryName)
        #expect(folder.deletingLastPathComponent() == root.standardizedFileURL)
        #expect(url.lastPathComponent == PersistenceConfig.dbFileName)
    }

    @Test("目录已存在时重复调用保持幂等（不重复创建）")
    func repeatedCallsAreIdempotent() throws {
        let root = try makeTemporaryDocumentsRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let first = PersistenceConfig.getDatabaseURL(baseDocumentsURL: root)
        let second = PersistenceConfig.getDatabaseURL(baseDocumentsURL: root)

        #expect(first == second)
        #expect(FileManager.default.fileExists(atPath: first.deletingLastPathComponent().path))
    }

    @Test("Documents 根目录本身不存在时也会被一并创建")
    func createsIntermediateDirectories() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("NettoPersistenceTest-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("nested", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let url = PersistenceConfig.getDatabaseURL(baseDocumentsURL: root)
        let folder = url.deletingLastPathComponent()

        #expect(FileManager.default.fileExists(atPath: root.path), "中间目录应被 withIntermediateDirectories 一并创建")
        #expect(FileManager.default.fileExists(atPath: folder.path))
    }
}
