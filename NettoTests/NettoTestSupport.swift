import Foundation
import KernelCore
import LumiFactory
import PluginPersistence
import SwiftData
@testable import TravelMode

/// hosted 单测装配助手：内存持久化容器 + 独立临时数据根，
/// 不触碰用户真实 db.sqlite 与 Application Support，用例之间互不污染。
@MainActor
enum NettoTestKernel {
    /// 共享装配引擎解释 TravelMode 清单后的真实内核（生产插件目录）。
    ///
    /// `PersistencePlugin` 生产配置指向固定 db.sqlite 路径（独立于 Storage
    /// 数据根），单测进程没有 App 沙箱容器会在 ModelContainer 创建时 fatalError，
    /// 故注入内存容器；启用状态 / 主题选择经数据根覆盖隔离到临时目录。
    static func make() async throws -> KernelCoreContainer {
        let container = try PersistenceService.inMemoryContainer()
        let plugins = NettoManifest.makePlugins()
        var manifest = NettoManifest.manifest
        manifest.makePlugins = {
            plugins.map { plugin -> any SuperPlugin in
                if plugin is PersistencePlugin {
                    return PersistencePlugin(container: container)
                }
                return plugin
            }
        }
        let root = makeTempRoot()
        manifest.storage.dataRootDirectoryOverride = { root }
        return try await KernelAssembler.makeKernel(manifest: manifest)
    }

    /// 自定义清单装配（Mock 插件 / 空插件目录的行为测试用），数据根隔离到临时目录。
    static func make(manifest: HostManifest) async throws -> KernelCoreContainer {
        var manifest = manifest
        if manifest.storage.dataRootDirectoryOverride == nil {
            let root = makeTempRoot()
            manifest.storage.dataRootDirectoryOverride = { root }
        }
        return try await KernelAssembler.makeKernel(manifest: manifest)
    }

    static func makeTempRoot() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("NettoTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}