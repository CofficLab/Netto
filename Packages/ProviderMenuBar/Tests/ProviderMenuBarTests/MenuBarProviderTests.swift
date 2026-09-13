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

    func testObserversReceiveOnlyTheContributionChangesTheyNeed() {
        let provider = DefaultMenuBarProviding()
        var events: [String] = []
        let observer = provider.addMenuBarObserver { event in
            switch event {
            case .contentItemsChanged: events.append("content")
            case .popupItemsChanged: events.append("popup")
            }
        }

        provider.addContent(MenuBarContribution(id: "status", title: "Status", ownerPluginID: "plugin-a") {
            Text("status")
        })
        provider.addPopup(MenuBarContribution(id: "panel", title: "Panel", ownerPluginID: "plugin-a") {
            Text("panel")
        })
        provider.removeItems(ownedBy: "plugin-a")

        XCTAssertEqual(events, ["content", "popup", "content", "popup"])

        observer.cancel()
        provider.addContent(MenuBarContribution(id: "other", title: "Other", ownerPluginID: "plugin-b") {
            Text("other")
        })
        XCTAssertEqual(events.count, 4)
    }

    func testRefreshModelTracksProviderAndCanResumeAfterCancellation() {
        let provider = DefaultMenuBarProviding()
        let refreshModel = MenuBarRefreshModel(provider: provider)

        provider.addPopup(MenuBarContribution(id: "first", title: "First", ownerPluginID: "plugin-a") {
            Text("first")
        })
        XCTAssertEqual(refreshModel.revision, 1)

        refreshModel.cancel()
        provider.addPopup(MenuBarContribution(id: "second", title: "Second", ownerPluginID: "plugin-a") {
            Text("second")
        })
        XCTAssertEqual(refreshModel.revision, 1)

        refreshModel.resume()
        provider.removeItems(ownedBy: "plugin-a")
        XCTAssertEqual(refreshModel.revision, 2)
    }
}
