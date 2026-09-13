import SwiftUI
import XCTest
@testable import ProviderMenuBar

@MainActor
final class MenuBarProviderTests: XCTestCase {
    func testPopupContributionsAreOrderedAndRemovedByOwner() {
        let provider = DefaultMenuBarProviding()
        provider.addPopup(MenuBarContribution(id: "later", title: "Later", order: 20, ownerPluginID: "plugin-b") {
            Text("later")
        })
        provider.addPopup(MenuBarContribution(id: "first", title: "First", order: 10, ownerPluginID: "plugin-a") {
            Text("first")
        })

        XCTAssertEqual(provider.popupItems.map(\.id), ["first", "later"])

        provider.removeItems(ownedBy: "plugin-a")

        XCTAssertEqual(provider.popupItems.map(\.id), ["later"])
    }

    func testDuplicateContributionIDKeepsFirstRegistration() {
        let provider = DefaultMenuBarProviding()
        provider.addPopup(MenuBarContribution(id: "dashboard", title: "First", ownerPluginID: "one") {
            Text("first")
        })
        provider.addPopup(MenuBarContribution(id: "dashboard", title: "Second", ownerPluginID: "two") {
            Text("second")
        })

        XCTAssertEqual(provider.popupItems.map(\.title), ["First"])
    }
}
