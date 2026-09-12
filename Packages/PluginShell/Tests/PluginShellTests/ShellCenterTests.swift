import Foundation
import SwiftUI
import XCTest
@testable import PluginShell
import ProviderShell

/// ShellCenter 行为测试：注册/排序/按 owner 撤回/窗口与 Toast。
@MainActor
final class ShellCenterTests: XCTestCase {

    private func makeContribution(
        id: String,
        position: ToolbarPosition = .left,
        order: Int = 100,
        owner: String = "P1"
    ) -> ToolbarContribution {
        ToolbarContribution(id: id, position: position, order: order, ownerPluginID: owner) {
            AnyView(EmptyView())
        }
    }

    func testToolbarOrderingAndPositions() {
        let center = ShellCenter()
        center.registerToolbar(makeContribution(id: "b", position: .center, order: 20))
        center.registerToolbar(makeContribution(id: "a", position: .left, order: 10))
        center.registerToolbar(makeContribution(id: "c", position: .left, order: 30))

        XCTAssertEqual(center.leftContributions.map(\.id), ["a", "c"])
        XCTAssertEqual(center.centerContributions.map(\.id), ["b"])
        XCTAssertEqual(center.rightContributions.count, 0)
    }

    func testRemoveToolbarByOwnerAndID() {
        let center = ShellCenter()
        center.registerToolbar(makeContribution(id: "a", owner: "P1"))
        center.registerToolbar(makeContribution(id: "b", owner: "P2"))
        center.removeToolbar(ownedBy: "P1")
        XCTAssertEqual(center.leftContributions.map(\.id), ["b"])

        center.removeToolbar(id: "b")
        XCTAssertEqual(center.leftContributions.count, 0)
    }

    func testSettingsEntriesOrderedAndRemovedByOwner() {
        let center = ShellCenter()
        center.registerEntry(SettingsEntry(id: "s2", order: 20, ownerPluginID: "P2") { AnyView(EmptyView()) })
        center.registerEntry(SettingsEntry(id: "s1", order: 10, ownerPluginID: "P1") { AnyView(EmptyView()) })
        XCTAssertEqual(center.entries.map(\.id), ["s1", "s2"])
        center.removeEntries(ownedBy: "P1")
        XCTAssertEqual(center.entries.map(\.id), ["s2"])
    }

    func testWindowContentOwnedByPlugin() {
        let center = ShellCenter()
        let contentA = WindowContentContribution(id: "w-store", title: "Store", ownerPluginID: "Store") {
            AnyView(EmptyView())
        }
        let contentB = WindowContentContribution(id: "w-guide", title: "Guide", ownerPluginID: "Guide") {
            AnyView(EmptyView())
        }
        center.registerContent(contentA)
        XCTAssertEqual(center.currentContent?.id, "w-store")
        center.registerContent(contentB)
        XCTAssertEqual(center.currentContent?.id, "w-guide")

        center.removeContent(ownedBy: "Store")
        XCTAssertEqual(center.currentContent?.id, "w-guide")
        center.hideWindow()
        XCTAssertNil(center.currentContent)
    }

    func testWindowRequestInvokesHostCallback() {
        let center = ShellCenter()
        var received: WindowRequest?
        center.onRequestOpen = { received = $0 }
        center.requestOpen(WindowRequest(windowID: "plugin-window", title: "Store"))
        XCTAssertEqual(received, WindowRequest(windowID: "plugin-window", title: "Store"))
    }

    func testToastStreamDelivers() async {
        let center = ShellCenter()
        let task = Task {
            var messages: [ToastMessage] = []
            for await message in center.observeToasts() {
                messages.append(message)
                if messages.count == 2 { return messages }
            }
            return messages
        }
        // 等待订阅建立。
        try? await Task.sleep(for: .milliseconds(100))
        center.post(ToastMessage(description: "one"))
        center.post(ToastMessage(description: "two"))
        let received = await task.value
        XCTAssertEqual(received.map(\.description), ["one", "two"])
        XCTAssertEqual(center.lastToast?.description, "two")
    }
}
