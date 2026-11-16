import Foundation
import ProviderFirewall
import ProviderFirewallEvents
import Testing
@testable import PluginFirewallDashboard

/// `UIProvider`（仪表盘 UI 状态容器）测试。
@MainActor
@Suite("UIProvider")
struct UIProviderTests {

    @Test("初始状态：面板关闭、展示类型为全部、无 popover、不显示升级引导")
    func initialState() {
        let provider = UIProvider()

        #expect(provider.dbVisible == false)
        #expect(provider.displayType == .All)
        #expect(provider.activePopoverAppId.isEmpty)
        #expect(provider.shouldShowUpgradeGuide == false)
    }

    @Test("showPopover 记录目标应用，shouldShowPopover 判定一致")
    func showPopover() {
        let provider = UIProvider()

        provider.showPopover(for: "com.app")

        #expect(provider.activePopoverAppId == "com.app")
        #expect(provider.shouldShowPopover(for: "com.app"))
        #expect(provider.shouldShowPopover(for: "com.other") == false)
    }

    @Test("hidePopover 清空当前 popover")
    func hidePopover() {
        let provider = UIProvider()
        provider.showPopover(for: "com.app")

        provider.hidePopover()

        #expect(provider.activePopoverAppId.isEmpty)
        #expect(provider.shouldShowPopover(for: "com.app") == false)
    }

    @Test("升级引导可显示与隐藏")
    func upgradeGuide() {
        let provider = UIProvider()

        provider.showUpgradeGuide()
        #expect(provider.shouldShowUpgradeGuide)

        provider.hideUpgradeGuide()
        #expect(provider.shouldShowUpgradeGuide == false)
    }

    @Test("cleanup 复位全部状态")
    func cleanup() {
        let provider = UIProvider()
        provider.dbVisible = true
        provider.displayType = .Rejected
        provider.showPopover(for: "com.app")
        provider.showUpgradeGuide()

        provider.cleanup()

        #expect(provider.dbVisible == false)
        #expect(provider.displayType == .All)
        #expect(provider.activePopoverAppId.isEmpty)
        #expect(provider.shouldShowUpgradeGuide == false)
    }
}

/// `ViewCompat`（视图层兼容扩展）测试。
@Suite("ViewCompat")
struct ViewCompatTests {

    // MARK: - FirewallState

    @Test("isRunning 仅在 running 为真")
    func isRunning() {
        #expect(FirewallState.running.isRunning())
        #expect(FirewallState.stopped.isRunning() == false)
        #expect(FirewallState.unknown.isRunning() == false)
        #expect(FirewallState.disabled.isRunning() == false)
    }

    @Test("isNotRunning 与 isRunning 互为取反")
    func isNotRunning() {
        #expect(FirewallState.running.isNotRunning() == false)
        #expect(FirewallState.stopped.isNotRunning())
        #expect(FirewallState.unknown.isNotRunning())
        #expect(FirewallState.installing.isNotRunning())
    }

    @Test("isStopped 仅在 stopped 为真")
    func isStopped() {
        #expect(FirewallState.stopped.isStopped())
        #expect(FirewallState.running.isStopped() == false)
        #expect(FirewallState.disabled.isStopped() == false)
    }

    // MARK: - FirewallFailureError

    @Test("FirewallFailureError 的描述取自失败消息")
    func failureErrorDescription() {
        let failure = FirewallFailure(domain: "NE", code: 1, message: "启用失败")
        let error = FirewallFailureError(failure: failure)

        #expect(error.errorDescription == "启用失败")
    }

    // MARK: - FirewallEventSnapshot

    @Test("isAllowed 依据 status 判定")
    func eventIsAllowed() {
        #expect(makeEvent(status: .allowed).isAllowed)
        #expect(makeEvent(status: .rejected).isAllowed == false)
    }

    @Test("timeFormatted 输出定长 19 字符的完整时间")
    func eventTimeFormatted() {
        let rendered = makeEvent(status: .allowed).timeFormatted
        #expect(rendered.count == 19)
    }

    @Test("description 输出 address:port")
    func eventDescription() {
        let event = makeEvent(status: .allowed)
        #expect(event.description == "example.com:443")
    }

    @Test("statusDescription 输出中文状态文案")
    func eventStatusDescription() {
        #expect(makeEvent(status: .allowed).statusDescription == "允许")
        #expect(makeEvent(status: .rejected).statusDescription == "阻止")
    }

    private func makeEvent(status: FirewallEventDecision) -> FirewallEventSnapshot {
        FirewallEventSnapshot(
            id: "e1",
            time: Date(timeIntervalSince1970: 1_700_000_000),
            address: "example.com",
            port: "443",
            sourceAppIdentifier: "com.app",
            status: status,
            direction: .outbound,
            appId: "com.app"
        )
    }
}

/// `AppProvider`（旧 UI 状态兼容层）测试。
@Suite("AppProvider")
struct AppProviderTests {

    @Test("初始状态与旧实现一致")
    func initialState() {
        let provider = AppProvider()

        #expect(provider.showSheet)
        #expect(provider.isImporting == false)
        #expect(provider.isDropping == false)
        #expect(provider.rightAlbumVisible == false)
    }

    @Test("emoji 常量保持稳定")
    func emoji() {
        #expect(AppProvider.emoji == "🐮")
    }
}

/// `LogPrefixed` 实例入口与后台线程标记测试。
@Suite("LogPrefixed 实例入口")
struct LogPrefixedInstanceTests {

    private struct Sample: LogPrefixed {}

    @Test("实例前缀与静态前缀一致")
    func instanceMatchesStatic() {
        let sample = Sample()
        #expect(sample.t == Sample.t)
        #expect(sample.t.contains("Sample"))
    }

    @Test("后台线程标记为 BG")
    func backgroundThreadMarker() {
        let prefix = DispatchQueue(label: "dashboard-log-prefixed").sync { Sample.t }
        #expect(prefix.contains("[BG]"))
    }

    @Test("主线程标记为 UI")
    func mainThreadMarker() async {
        let prefix = await MainActor.run { Sample.t }
        #expect(prefix.contains("[UI]"))
    }
}
