import SwiftUI
import XCTest
@testable import ProviderMenuBar

/// 菜单栏 Provider 的视图工厂、排序与观察者生命周期测试。
///
/// 既有 `MenuBarProviderTests` 覆盖 popover 排序、去重与观察者事件序列，
/// 本文件补齐常驻内容（content）路径、视图工厂、排序并列项与取消语义。
@MainActor
final class MenuBarContentTests: XCTestCase {

    private func makeContribution(
        id: String,
        title: String = "Item",
        order: Int = 200,
        owner: String = "plugin-a"
    ) -> MenuBarContribution {
        MenuBarContribution(id: id, title: title, order: order, ownerPluginID: owner) {
            Text(title)
        }
    }

    // MARK: - 常驻内容（content）路径

    func testContentItemsAreRegisteredAndSorted() {
        let provider = DefaultMenuBarProviding()
        provider.addContent(makeContribution(id: "later", title: "Later", order: 20))
        provider.addContent(makeContribution(id: "first", title: "First", order: 10))

        XCTAssertEqual(provider.contentItems.map(\.id), ["first", "later"])
        XCTAssertTrue(provider.popupItems.isEmpty)
    }

    func testDuplicateContentIDKeepsFirstRegistration() {
        let provider = DefaultMenuBarProviding()
        provider.addContent(makeContribution(id: "status", title: "First", owner: "one"))
        provider.addContent(makeContribution(id: "status", title: "Second", owner: "two"))

        XCTAssertEqual(provider.contentItems.map(\.title), ["First"])
        XCTAssertEqual(provider.contentItems.first?.ownerPluginID, "one")
    }

    func testEqualOrderIsBrokenByID() {
        let provider = DefaultMenuBarProviding()
        provider.addContent(makeContribution(id: "b", order: 10))
        provider.addContent(makeContribution(id: "a", order: 10))
        provider.addContent(makeContribution(id: "c", order: 10))

        // order 相同时按 id 升序，保证顺序稳定。
        XCTAssertEqual(provider.contentItems.map(\.id), ["a", "b", "c"])
    }

    func testRemoveItemsRemovesContentByOwner() {
        let provider = DefaultMenuBarProviding()
        provider.addContent(makeContribution(id: "a", owner: "plugin-a"))
        provider.addContent(makeContribution(id: "b", owner: "plugin-b"))

        provider.removeItems(ownedBy: "plugin-a")

        XCTAssertEqual(provider.contentItems.map(\.id), ["b"])
    }

    func testRemoveItemsWithoutMatchDoesNotNotify() {
        let provider = DefaultMenuBarProviding()
        provider.addContent(makeContribution(id: "a", owner: "plugin-a"))
        var events: [String] = []
        let handle = provider.addMenuBarObserver { event in
            switch event {
            case .contentItemsChanged: events.append("content")
            case .popupItemsChanged: events.append("popup")
            }
        }
        defer { handle.cancel() }

        provider.removeItems(ownedBy: "plugin-unknown")

        // 没有匹配项时不发变更通知。
        XCTAssertTrue(events.isEmpty)
    }

    // MARK: - 视图工厂

    func testMakeContentViewBuildsView() {
        let provider = DefaultMenuBarProviding()
        provider.addContent(makeContribution(id: "a"))

        let view = provider.makeContentView()

        XCTAssertNotNil(view)
    }

    func testMakePopupViewBuildsView() {
        let provider = DefaultMenuBarProviding()
        provider.addPopup(makeContribution(id: "p"))

        let view = provider.makePopupView()

        XCTAssertNotNil(view)
    }

    func testContributionMakeViewProducesView() {
        let contribution = makeContribution(id: "a", title: "A")

        let view = contribution.makeView()

        XCTAssertNotNil(view)
    }

    func testContributionKeepsDeclaredFields() {
        let contribution = MenuBarContribution(
            id: "status",
            title: "状态",
            order: 42,
            ownerPluginID: "plugin-x"
        ) {
            Text("状态")
        }

        XCTAssertEqual(contribution.id, "status")
        XCTAssertEqual(contribution.title, "状态")
        XCTAssertEqual(contribution.order, 42)
        XCTAssertEqual(contribution.ownerPluginID, "plugin-x")
    }

    func testContributionDefaultOrderIs200() {
        let contribution = makeContribution(id: "a")
        XCTAssertEqual(contribution.order, 200)
    }

    // MARK: - 观察者句柄

    func testObserverHandleCancelIsIdempotent() {
        let provider = DefaultMenuBarProviding()
        var events: [String] = []
        let handle = provider.addMenuBarObserver { event in
            switch event {
            case .contentItemsChanged: events.append("content")
            case .popupItemsChanged: events.append("popup")
            }
        }

        handle.cancel()
        // 重复取消是安全的，且不会重复触发回调。
        handle.cancel()

        provider.addContent(makeContribution(id: "a"))
        XCTAssertTrue(events.isEmpty)
    }

    func testMultipleObserversAllReceiveEvents() {
        let provider = DefaultMenuBarProviding()
        var first = 0
        var second = 0
        let handleA = provider.addMenuBarObserver { _ in first += 1 }
        let handleB = provider.addMenuBarObserver { _ in second += 1 }
        defer {
            handleA.cancel()
            handleB.cancel()
        }

        provider.addContent(makeContribution(id: "a"))

        XCTAssertEqual(first, 1)
        XCTAssertEqual(second, 1)
    }
}

/// `MenuBarRefreshModel` 的订阅生命周期测试。
@MainActor
final class MenuBarRefreshModelLifecycleTests: XCTestCase {

    func testInitSubscribesImmediately() {
        let provider = DefaultMenuBarProviding()
        let model = MenuBarRefreshModel(provider: provider)

        provider.addPopup(MenuBarContribution(id: "a", title: "A", ownerPluginID: "p") { Text("A") })

        XCTAssertEqual(model.revision, 1)
    }

    func testResumeIsIdempotentWhenAlreadySubscribed() {
        let provider = DefaultMenuBarProviding()
        let model = MenuBarRefreshModel(provider: provider)

        // 重复 resume 不会重复订阅，事件不应被计数两次。
        model.resume()
        provider.addPopup(MenuBarContribution(id: "a", title: "A", ownerPluginID: "p") { Text("A") })

        XCTAssertEqual(model.revision, 1)
    }

    func testCancelThenResumeRestoresSubscription() {
        let provider = DefaultMenuBarProviding()
        let model = MenuBarRefreshModel(provider: provider)

        model.cancel()
        provider.addPopup(MenuBarContribution(id: "a", title: "A", ownerPluginID: "p") { Text("A") })
        XCTAssertEqual(model.revision, 0)

        model.resume()
        provider.addPopup(MenuBarContribution(id: "b", title: "B", ownerPluginID: "p") { Text("B") })
        XCTAssertEqual(model.revision, 1)
    }

    func testCancelIsIdempotent() {
        let provider = DefaultMenuBarProviding()
        let model = MenuBarRefreshModel(provider: provider)

        model.cancel()
        model.cancel()

        provider.addPopup(MenuBarContribution(id: "a", title: "A", ownerPluginID: "p") { Text("A") })
        XCTAssertEqual(model.revision, 0)
    }
}
