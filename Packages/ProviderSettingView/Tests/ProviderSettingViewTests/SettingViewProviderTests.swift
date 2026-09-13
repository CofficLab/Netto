import SwiftUI
import XCTest

@testable import ProviderSettingView

/// 默认设置 Provider 行为测试：排序、默认选中、通知、去重、撤回。
@MainActor
final class SettingViewProviderTests: XCTestCase {
    private func makeEntries() -> [SettingEntryItem] {
        [
            SettingEntryItem(id: "b", title: "B", systemImage: "circle", order: 20) {
                Text("B-detail")
            },
            SettingEntryItem(id: "a", title: "A", systemImage: "square", order: 10) {
                Text("A-detail")
            },
        ]
    }

    func testRegisterEntriesSortsByOrderAndSelectsFirst() {
        let provider = DefaultSettingViewProviding()
        provider.registerEntries(makeEntries())

        XCTAssertEqual(provider.entries.map(\.id), ["a", "b"])
        XCTAssertEqual(provider.selectedEntryID, "a")
    }

    func testAddEntriesDeduplicatesKeepingFirstRegistered() {
        let provider = DefaultSettingViewProviding()
        provider.addEntries([
            SettingEntryItem(id: "a", title: "A", systemImage: "square", order: 10) {
                Text("A-1")
            },
        ])
        provider.addEntries([
            SettingEntryItem(id: "a", title: "A2", systemImage: "square", order: 10) {
                Text("A-2")
            },
            SettingEntryItem(id: "c", title: "C", systemImage: "circle", order: 30) {
                Text("C")
            },
        ])

        XCTAssertEqual(provider.entries.map(\.id), ["a", "c"])
        XCTAssertEqual(provider.entries.count, 2)
    }

    func testSelectEntryKeepsSelectionAndNotifies() {
        let provider = DefaultSettingViewProviding()
        provider.registerEntries(makeEntries())
        var events: [SettingViewEvent] = []
        let handle = provider.addSettingViewObserver { events.append($0) }

        provider.selectEntry(id: "b")
        XCTAssertEqual(provider.selectedEntryID, "b")
        XCTAssertTrue(events.contains { event in
            if case .selectedEntryChanged("b") = event { return true }
            return false
        })

        // 相同 id 重复选中不通知。
        events.removeAll()
        provider.selectEntry(id: "b")
        XCTAssertTrue(events.isEmpty)

        handle.cancel()
    }

    func testRemoveEntriesDropsContributedIDs() {
        let provider = DefaultSettingViewProviding()
        provider.addEntries(makeEntries())
        provider.removeEntries(ids: ["a"])

        XCTAssertEqual(provider.entries.map(\.id), ["b"])
        // 选中项失效后回退到第一个。
        XCTAssertEqual(provider.selectedEntryID, "b")
    }

    func testSettingViewRenders() {
        let provider = DefaultSettingViewProviding()
        provider.addEntries(makeEntries())
        provider.selectEntry(id: "b")

        let view = provider.makeSettingView()
        XCTAssertNotNil(view)
        XCTAssertEqual(provider.entries.count, 2)
        XCTAssertEqual(provider.selectedEntryID, "b")
    }

    func testObserverHandleCancellationStopsDelivery() {
        let provider = DefaultSettingViewProviding()
        provider.registerEntries(makeEntries())
        var count = 0
        let handle = provider.addSettingViewObserver { _ in count += 1 }

        provider.selectEntry(id: "b")
        XCTAssertEqual(count, 1)

        handle.cancel()
        provider.selectEntry(id: "a")
        XCTAssertEqual(count, 1)
    }
}
