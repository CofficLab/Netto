import Foundation
import Testing
@testable import ProviderPersistence

/// `PersistenceConfig` 路径规则测试。
///
/// 兼容红线：插件目录名 = pluginID、库文件名固定；
/// 旧版单库仍位于 `~/Documents/debug|production/db.sqlite`（一次性迁移来源）。
@MainActor
@Suite("PersistenceConfig")
struct PersistenceConfigTests {

    @Test("插件 id 与库文件名为稳定常量")
    func stableConstants() {
        #expect(PersistenceConfig.eventsPluginID == "eventstore")
        #expect(PersistenceConfig.settingsPluginID == "appsettings")
        #expect(PersistenceConfig.eventsFileName == "events.sqlite")
        #expect(PersistenceConfig.settingsFileName == "settings.sqlite")
        #expect(PersistenceConfig.appName == "Netpause")
    }

    @Test("旧版库位于 Documents 下与构建配置匹配的子目录")
    func legacyDatabaseURLMatchesBuildConfiguration() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("NetpausePersistenceConfigTest-\(UUID().uuidString)", isDirectory: true)
        let url = PersistenceConfig.legacyDatabaseURL(baseDocumentsURL: root)

        #if DEBUG
        let expectedDirectoryName = "debug"
        #else
        let expectedDirectoryName = "production"
        #endif

        #expect(url.lastPathComponent == "db.sqlite")
        #expect(url.deletingLastPathComponent().lastPathComponent == expectedDirectoryName)
        #expect(url.deletingLastPathComponent().deletingLastPathComponent() == root.standardizedFileURL)
    }

    @Test("生产旧库路径基于用户 Documents 目录")
    func legacyDatabaseURLUsesDocuments() {
        #expect(
            PersistenceConfig.legacyDatabaseURL
                == PersistenceConfig.legacyDatabaseURL(baseDocumentsURL: PersistenceConfig.documentsURL)
        )
    }
}
