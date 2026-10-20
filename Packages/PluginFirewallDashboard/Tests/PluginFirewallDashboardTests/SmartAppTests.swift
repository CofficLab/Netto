import Foundation
import Testing
@testable import PluginFirewallDashboard

/// SmartApp 值语义与推导属性测试。
@Suite("SmartApp")
struct SmartAppTests {

    // MARK: - 等值语义

    @Test("全字段一致时相等，任一字段不同则不等")
    func equality() {
        let a = SmartApp(
            id: "com.app",
            name: "App",
            isSystemApp: true,
            hidden: true,
            isSample: true,
            isProxy: true,
            bundleURL: URL(fileURLWithPath: "/Applications/App.app")
        )
        let b = SmartApp(
            id: "com.app",
            name: "App",
            isSystemApp: true,
            hidden: true,
            isSample: true,
            isProxy: true,
            bundleURL: URL(fileURLWithPath: "/Applications/App.app")
        )
        #expect(a == b)

        // 逐字段扰动都应打破相等。
        #expect(a != SmartApp(id: "other", name: "App", isSystemApp: true, hidden: true, isSample: true, isProxy: true, bundleURL: a.bundleURL))
        #expect(a != SmartApp(id: "com.app", name: "Other", isSystemApp: true, hidden: true, isSample: true, isProxy: true, bundleURL: a.bundleURL))
        #expect(a != SmartApp(id: "com.app", name: "App", isSystemApp: false, hidden: true, isSample: true, isProxy: true, bundleURL: a.bundleURL))
        #expect(a != SmartApp(id: "com.app", name: "App", isSystemApp: true, hidden: false, isSample: true, isProxy: true, bundleURL: a.bundleURL))
        #expect(a != SmartApp(id: "com.app", name: "App", isSystemApp: true, hidden: true, isSample: false, isProxy: true, bundleURL: a.bundleURL))
        #expect(a != SmartApp(id: "com.app", name: "App", isSystemApp: true, hidden: true, isSample: true, isProxy: false, bundleURL: a.bundleURL))
        #expect(a != SmartApp(id: "com.app", name: "App", isSystemApp: true, hidden: true, isSample: true, isProxy: true, bundleURL: nil))
    }

    // MARK: - 推导属性

    @Test("hasId / hasNoId 互为取反且与空串一致")
    func idPresence() {
        #expect(SmartApp(id: "com.app", name: "App").hasId)
        #expect(!SmartApp(id: "com.app", name: "App").hasNoId)
        #expect(SmartApp(id: "", name: "App").hasNoId)
        #expect(!SmartApp(id: "", name: "App").hasId)
    }

    @Test("isNotSample 与 isSample 取反")
    func sampleFlag() {
        #expect(SmartApp(id: "a", name: "A").isNotSample)
        #expect(SmartApp(id: "a", name: "A", isSample: true).isSample)
        #expect(!SmartApp(id: "a", name: "A", isSample: true).isNotSample)
    }

    // MARK: - 默认值

    @Test("默认构造仅 id/name 有值，其余为 false / nil")
    func defaults() {
        let app = SmartApp(id: "com.app", name: "App")
        #expect(app.id == "com.app")
        #expect(app.name == "App")
        #expect(!app.isSystemApp)
        #expect(!app.hidden)
        #expect(!app.isSample)
        #expect(!app.isProxy)
        #expect(app.bundleURL == nil)
    }

    // MARK: - 未知应用

    @Test("unknownApp 生成 id 保留、名称为「未知」的非系统应用")
    func unknownApp() {
        let app = SmartApp.unknownApp("com.unknown.app")
        #expect(app.id == "com.unknown.app")
        #expect(app.name == "未知")
        #expect(!app.isSystemApp)
        #expect(!app.hidden)
        #expect(!app.isProxy)
    }
}
