import Foundation
import Testing
@testable import PluginFirewallDashboard

/// 系统应用目录（`SmartApp.allSystemApps`）与查找逻辑测试。
@Suite("SmartApp 系统应用")
struct SmartAppSystemTests {

    @Test("系统应用目录非空、id 唯一且全部标记为系统应用")
    func systemCatalogInvariants() {
        let apps = SmartApp.allSystemApps
        #expect(!apps.isEmpty)

        let ids = apps.map(\.id)
        #expect(Set(ids).count == ids.count, "系统应用 id 必须唯一，否则列表 key 会冲突")

        for app in apps {
            #expect(app.isSystemApp, "目录内所有条目都应标记为系统应用：\(app.id)")
            #expect(!app.id.isEmpty)
            #expect(!app.name.isEmpty)
        }
    }

    @Test("系统应用 id 以点开头（Apple 约定）")
    func systemIdsUseDottedConvention() {
        for app in SmartApp.allSystemApps {
            #expect(app.id.hasPrefix("."), "系统应用 id 应以 '.' 开头：\(app.id)")
        }
    }

    @Test("getSystemApp 命中已知 id")
    func getSystemAppKnown() throws {
        let known = try #require(SmartApp.allSystemApps.first)
        let found = SmartApp.getSystemApp(known.id)
        let app = try #require(found)
        #expect(app == known)
        #expect(app.isSystemApp)
    }

    @Test("getSystemApp 对未收录但以点开头的 id 回退为隐藏的未知系统应用")
    func getSystemAppUnknownDotted() throws {
        let app = try #require(SmartApp.getSystemApp(".com.not.registered.agent"))
        #expect(app.id == ".com.not.registered.agent")
        #expect(app.name == "未知系统应用")
        #expect(app.isSystemApp)
        #expect(app.hidden, "未知系统应用应隐藏，不进入常规列表")
    }

    @Test("getSystemApp 对不以点开头的未知 id 返回 nil")
    func getSystemAppUnknownPlainReturnsNil() {
        // 非系统 id 应交由调用方走 unknownApp 分支，而不是伪造系统应用。
        #expect(SmartApp.getSystemApp("com.some.thirdparty.app") == nil)
        #expect(SmartApp.getSystemApp("") == nil)
    }

    @Test("samples 与系统应用目录一致")
    func samplesMirrorSystemApps() {
        #expect(SmartApp.samples == SmartApp.allSystemApps)
    }
}
