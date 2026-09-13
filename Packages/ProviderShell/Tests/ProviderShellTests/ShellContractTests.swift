import Foundation
import SwiftUI
import XCTest
@testable import ProviderShell

/// 契约值类型测试：贡献 ID/排序/撤回归属。
final class ShellContractTests: XCTestCase {

    func testToolbarContributionOrderingAndIdentity() {
        let low = ToolbarContribution(id: "btn-a", position: .left, order: 10, ownerPluginID: "P1") {
            AnyView(EmptyView())
        }
        let high = ToolbarContribution(id: "btn-b", position: .left, order: 20, ownerPluginID: "P1") {
            AnyView(EmptyView())
        }
        XCTAssertNotEqual(low.id, high.id)
        let contributions: [ToolbarContribution] = [high, low]
        XCTAssertEqual(contributions.sorted { $0.order < $1.order }.map(\.id), ["btn-a", "btn-b"])
        XCTAssertEqual(low.position, ToolbarPosition.left)
        XCTAssertEqual(low.ownerPluginID, "P1")
    }

    func testWindowRequestValueSemantics() {
        let req = WindowRequest(windowID: "plugin-window", title: "Store")
        XCTAssertEqual(req, WindowRequest(windowID: "plugin-window", title: "Store"))
        XCTAssertNotEqual(req, WindowRequest(windowID: "plugin-window", title: "Guide"))
    }

    func testToastMessageValueSemantics() {
        let ok = ToastMessage(description: "完成", isError: false)
        let err = ToastMessage(description: "失败", isError: true)
        XCTAssertNotEqual(ok, err)
        XCTAssertEqual(ok.channel, "default")
    }
}
