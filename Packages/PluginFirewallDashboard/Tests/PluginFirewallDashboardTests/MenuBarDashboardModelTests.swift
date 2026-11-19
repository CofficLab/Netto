import Testing
@testable import PluginFirewallDashboard

@MainActor
@Suite("实时应用合并")
struct MenuBarDashboardModelMergingTests {

    @Test("历史为空时，实时应用按名称补进全部与允许")
    func includesLiveWhenBaseEmpty() {
        let live = [app("com.alpha", "Alpha"), app("com.beta", "Beta")]

        #expect(MenuBarDashboardModel.merging([], withLive: live, displayType: .All, deniedIds: []).map(\.id) == ["com.alpha", "com.beta"])
        #expect(MenuBarDashboardModel.merging([], withLive: live, displayType: .Allowed, deniedIds: []).map(\.id) == ["com.alpha", "com.beta"])
    }

    @Test("禁止筛选不展示实时应用")
    func rejectedIgnoresLive() {
        let live = [app("com.alpha", "Alpha")]

        #expect(MenuBarDashboardModel.merging([], withLive: live, displayType: .Rejected, deniedIds: []).isEmpty)
    }

    @Test("历史应用不重复，被禁止的应用置顶且不进入允许列表")
    func dedupesAndHonorsDenied() {
        let base = [app("com.alpha", "Alpha")]
        let live = [app("com.alpha", "Alpha"), app("com.beta", "Beta")]

        let all = MenuBarDashboardModel.merging(base, withLive: live, displayType: .All, deniedIds: ["com.beta"])
        #expect(all.map(\.id) == ["com.beta", "com.alpha"])

        let allowed = MenuBarDashboardModel.merging(base, withLive: live, displayType: .Allowed, deniedIds: ["com.beta"])
        #expect(allowed.map(\.id) == ["com.alpha"])
    }

    @Test("空 id 的实时应用被忽略")
    func ignoresEmptyId() {
        let live = [app("", "")]

        #expect(MenuBarDashboardModel.merging([], withLive: live, displayType: .All, deniedIds: []).isEmpty)
    }

    private func app(_ id: String, _ name: String) -> SmartApp {
        SmartApp(id: id, name: name)
    }
}