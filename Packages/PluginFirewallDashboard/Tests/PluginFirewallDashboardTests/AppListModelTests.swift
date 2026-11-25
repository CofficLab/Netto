import AppKit
import ProviderFirewall
import Testing
@testable import PluginFirewallDashboard

/// 菜单栏列表的合并、排序与行级网速更新。
@MainActor
@Suite("菜单栏应用合并")
struct MenuBarAppsModelTests {

    @Test("历史为空时，实时应用按名称补进全部与允许")
    func includesLiveWhenBaseEmpty() {
        let (model, catalog) = makeModel()
        model.applySnapshot(
            catalog: catalog,
            sessionIds: [],
            deniedIds: [],
            speeds: [speed("com.alpha"), speed("com.beta")]
        )

        #expect(model.rows(for: .All).map(\.id) == ["com.alpha", "com.beta"])
        #expect(model.rows(for: .Allowed).map(\.id) == ["com.alpha", "com.beta"])
    }

    @Test("禁止筛选只展示被禁止的应用")
    func rejectedOnlyShowsDenied() {
        let (model, catalog) = makeModel()
        model.applySnapshot(
            catalog: catalog,
            sessionIds: ["com.alpha"],
            deniedIds: ["com.beta"],
            speeds: [speed("com.alpha")]
        )

        #expect(model.rows(for: .Rejected).map(\.id) == ["com.beta"])
    }

    @Test("历史与实时去重，被禁止的应用置顶且不进入允许列表")
    func dedupesAndHonorsDenied() {
        let (model, catalog) = makeModel()
        model.applySnapshot(
            catalog: catalog,
            sessionIds: ["com.alpha"],
            deniedIds: ["com.beta"],
            speeds: [speed("com.alpha"), speed("com.beta")]
        )

        #expect(model.rows(for: .All).map(\.id) == ["com.beta", "com.alpha"])
        #expect(model.rows(for: .Allowed).map(\.id) == ["com.alpha"])
    }

    @Test("空 id 的应用被忽略")
    func ignoresEmptyId() {
        let (model, catalog) = makeModel()
        model.applySnapshot(
            catalog: catalog,
            sessionIds: [""],
            deniedIds: [],
            speeds: [speed("")]
        )

        #expect(model.rows.isEmpty)
    }

    @Test("网速更新只改对应行，不重排列表")
    func speedUpdateKeepsOrderAndIdentity() {
        let (model, catalog) = makeModel()
        model.applySnapshot(
            catalog: catalog,
            sessionIds: ["com.alpha", "com.beta"],
            deniedIds: [],
            speeds: []
        )
        let before = model.rows
        #expect(before.map(\.id) == ["com.alpha", "com.beta"])

        model.applySnapshot(
            catalog: catalog,
            sessionIds: ["com.alpha", "com.beta"],
            deniedIds: [],
            speeds: [AppNetworkSpeed(appId: "com.beta", downloadBytesPerSecond: 1024, uploadBytesPerSecond: 0)]
        )

        #expect(model.rows.map(\.id) == ["com.alpha", "com.beta"])
        // 行对象身份保持，SwiftUI 只失效网速变化的行。
        #expect(model.rows[1] === before[1])
        #expect(model.rows[1].speed?.downloadBytesPerSecond == 1024)
        #expect(model.rows[0].speed == nil)
    }

    private func speed(_ id: String) -> AppNetworkSpeed {
        AppNetworkSpeed(appId: id, downloadBytesPerSecond: 100, uploadBytesPerSecond: 0)
    }

    private func makeModel() -> (MenuBarAppsModel, StubCatalog) {
        let catalog = StubCatalog()
        catalog.apps = [
            "com.alpha": SmartApp(id: "com.alpha", name: "Alpha"),
            "com.beta": SmartApp(id: "com.beta", name: "Beta"),
        ]
        return (MenuBarAppsModel(), catalog)
    }
}

@MainActor
final class StubCatalog: AppResolving {
    var apps: [String: SmartApp] = [:]

    func app(for id: String) -> SmartApp {
        apps[id] ?? SmartApp.unknownApp(id)
    }

    func icon(for id: String) -> NSImage? { nil }

    func observeChanges() -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
}