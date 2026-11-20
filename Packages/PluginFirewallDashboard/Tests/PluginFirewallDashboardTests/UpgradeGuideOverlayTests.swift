import AppKit
import ProviderFirewall
import SwiftUI
import Testing
@testable import PluginFirewallDashboard

/// 升级引导覆盖层：达到免费版限制时，引导必须渲染在应用详情之上。
@MainActor
@Suite("升级引导覆盖层")
struct UpgradeGuideOverlayTests {

    /// 渲染覆盖层并返回其实际占用尺寸。
    private func renderedSize(_ ui: UIProvider) -> CGSize {
        let hosting = NSHostingView(
            rootView: UpgradeGuideOverlay(state: nil).environmentObject(ui)
        )
        hosting.frame = CGRect(x: 0, y: 0, width: 360, height: 360)
        hosting.layoutSubtreeIfNeeded()
        return hosting.fittingSize
    }

    @Test("停留在应用详情时覆盖层渲染出升级引导")
    func overlayRendersGuideWhileAppSelected() {
        let ui = UIProvider()
        ui.presentUpgradeLimit()
        ui.selectApp("com.example.app")

        #expect(ui.showsUpgradeOverlay)
        let size = renderedSize(ui)
        #expect(size.width > 0 && size.height > 0)
    }

    @Test("未停留在应用详情时覆盖层不渲染内容")
    func overlayEmptyWithoutSelection() {
        let ui = UIProvider()
        ui.presentUpgradeLimit()

        #expect(!ui.showsUpgradeOverlay)
        let size = renderedSize(ui)
        #expect(size.width == 0 || size.height == 0)
    }
}
