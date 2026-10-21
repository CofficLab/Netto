import AppKit
import SwiftUI
import XCTest
@testable import ProviderMenuBar

/// 菜单栏视图工厂的渲染路径测试。
///
/// `makeContentView()` / `makePopupView()` 里的 `ForEach` 闭包是
/// SwiftUI 的 ViewBuilder 惰性求值：只有真正渲染视图时才会执行。
/// 这里用 `NSHostingView` 承载并触发布局，确保这些闭包被求值。
@MainActor
final class MenuBarViewFactoryRenderTests: XCTestCase {

    func testContentViewFactoryRendersContentItems() {
        let provider = DefaultMenuBarProviding()
        provider.addContent(MenuBarContribution(id: "a", title: "A", ownerPluginID: "p") { Text("A") })
        provider.addContent(MenuBarContribution(id: "b", title: "B", ownerPluginID: "p") { Text("B") })

        let host = NSHostingView(rootView: provider.makeContentView())
        host.frame = CGRect(x: 0, y: 0, width: 120, height: 40)
        host.layoutSubtreeIfNeeded()

        XCTAssertGreaterThan(host.fittingSize.width, 0)
    }

    func testPopupViewFactoryRendersPopupItems() {
        let provider = DefaultMenuBarProviding()
        provider.addPopup(MenuBarContribution(id: "a", title: "A", ownerPluginID: "p") { Text("A") })
        provider.addPopup(MenuBarContribution(id: "b", title: "B", ownerPluginID: "p") { Text("B") })

        let host = NSHostingView(rootView: provider.makePopupView())
        host.frame = CGRect(x: 0, y: 0, width: 120, height: 80)
        host.layoutSubtreeIfNeeded()

        XCTAssertGreaterThan(host.fittingSize.height, 0)
    }

    func testViewFactoriesRenderWithNoItems() {
        let provider = DefaultMenuBarProviding()

        let contentHost = NSHostingView(rootView: provider.makeContentView())
        contentHost.frame = CGRect(x: 0, y: 0, width: 120, height: 40)
        contentHost.layoutSubtreeIfNeeded()

        let popupHost = NSHostingView(rootView: provider.makePopupView())
        popupHost.frame = CGRect(x: 0, y: 0, width: 120, height: 80)
        popupHost.layoutSubtreeIfNeeded()

        XCTAssertNotNil(contentHost)
        XCTAssertNotNil(popupHost)
    }
}
