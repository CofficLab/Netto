import Foundation
import Testing
@testable import PluginFirewallDashboard

/// 免费版限制：达到禁止数量上限时必须给出可见反馈。
@MainActor
@Suite("免费版限制反馈")
struct FreeTierDenyGuardTests {

    @Test("Pro 用户不受限制")
    func proIsNotLimited() {
        #expect(FreeTierDenyGuard.decide(isProOrHigher: true, deniedCount: 99) == .allowed)
    }

    @Test("未达上限时允许禁止")
    func belowLimitIsAllowed() {
        #expect(FreeTierDenyGuard.decide(isProOrHigher: false, deniedCount: 4) == .allowed)
    }

    @Test("达到上限时要求升级并给出提示文案")
    func atLimitRequiresUpgrade() {
        let decision = FreeTierDenyGuard.decide(isProOrHigher: false, deniedCount: 5)

        guard case .upgradeRequired(let message) = decision else {
            Issue.record("达到上限时应要求升级，实际为 \(String(describing: decision))")
            return
        }
        #expect(message.isEmpty == false)
    }

    @Test("达到上限时进入升级引导状态")
    func upgradeLimitShowsGuide() {
        let ui = UIProvider()

        ui.presentUpgradeLimit()

        #expect(ui.shouldShowUpgradeGuide)
    }

    @Test("关闭升级引导后状态复位")
    func dismissUpgradeGuideClearsState() {
        let ui = UIProvider()
        ui.presentUpgradeLimit()

        ui.hideUpgradeGuide()

        #expect(ui.shouldShowUpgradeGuide == false)
    }
}
