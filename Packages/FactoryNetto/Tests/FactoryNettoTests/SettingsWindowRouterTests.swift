import Foundation
import ProviderSettingView
import ProviderShell
import SwiftUI
import XCTest
@testable import FactoryNetto

/// 记录选中入口的 Mock 设置视图契约。
@MainActor
private final class MockSettingViewProviding: SettingViewProviding {
    private(set) var entries: [SettingEntryItem]
    private(set) var selectedEntryID: String?
    private(set) var selectCallCount = 0

    init(entries: [SettingEntryItem], selectedEntryID: String? = nil) {
        self.entries = entries
        self.selectedEntryID = selectedEntryID
    }

    func selectEntry(id: String?) {
        selectCallCount += 1
        selectedEntryID = id
    }

    func registerEntries(_ entries: [SettingEntryItem]) {
        self.entries = entries
    }

    func makeSettingView() -> AnyView {
        AnyView(EmptyView())
    }
}

/// 构造一个设置入口项（`SettingEntryItem` 需要详情视图工厂）。
@MainActor
private func makeEntry(_ id: String, title: String, order: Int) -> SettingEntryItem {
    SettingEntryItem(id: id, title: title, systemImage: "gearshape", order: order) {
        EmptyView()
    }
}

/// `SettingsWindowRouter` 单元测试。
///
/// 重点覆盖**深链语义**与**路由决策**：
/// - 深链入口必须先校验（不存在则不选中）再选中；
/// - 窗口已存在时只前置，不新建；
/// - 通知监听挂在常驻宿主上（不受设置窗口场景是否创建影响）。
@MainActor
final class SettingsWindowRouterTests: XCTestCase {

    // MARK: - 深链

    func testOpenSettingsWithValidEntryIDSelectsThatEntry() {
        let router = SettingsWindowRouter()
        let provider = MockSettingViewProviding(
            entries: [
                makeEntry("appearance", title: "外观", order: 2),
                makeEntry("general", title: "通用", order: 5),
            ]
        )
        router.attach(settingViewProvider: provider)

        router.openSettings(entryID: "general")

        XCTAssertEqual(provider.selectedEntryID, "general", "深链应选中目标入口")
        XCTAssertEqual(provider.selectCallCount, 1)
        XCTAssertEqual(router.lastOpenedEntryID, "general")
        XCTAssertTrue(router.didOpenSettingsWindow)
    }

    func testOpenSettingsWithUnknownEntryIDKeepsCurrentSelection() {
        let router = SettingsWindowRouter()
        let provider = MockSettingViewProviding(
            entries: [makeEntry("appearance", title: "外观", order: 2)],
            selectedEntryID: "appearance"
        )
        router.attach(settingViewProvider: provider)

        router.openSettings(entryID: "does-not-exist")

        XCTAssertEqual(provider.selectedEntryID, "appearance", "入口不存在时不应改变选中项")
        XCTAssertEqual(provider.selectCallCount, 0, "入口不存在时不应调用 selectEntry")
        XCTAssertTrue(router.didOpenSettingsWindow, "即使入口无效也应打开设置窗口")
    }

    func testOpenSettingsWithoutEntryIDDoesNotChangeSelection() {
        let router = SettingsWindowRouter()
        let provider = MockSettingViewProviding(
            entries: [makeEntry("appearance", title: "外观", order: 2)],
            selectedEntryID: "appearance"
        )
        router.attach(settingViewProvider: provider)

        router.openSettings()

        XCTAssertEqual(provider.selectCallCount, 0)
        XCTAssertNil(router.lastOpenedEntryID)
    }

    // MARK: - 契约注入

    func testAttachSettingViewProviderIgnoresNil() {
        let router = SettingsWindowRouter()
        let provider = MockSettingViewProviding(
            entries: [makeEntry("general", title: "通用", order: 5)]
        )
        router.attach(settingViewProvider: provider)
        // nil 不得覆盖已绑定的契约（欢迎窗口 onAppear 可能早于内核启动）。
        router.attach(settingViewProvider: nil)

        router.openSettings(entryID: "general")

        XCTAssertEqual(provider.selectedEntryID, "general")
    }

    func testOpenSettingsWithoutProviderDoesNotCrash() {
        let router = SettingsWindowRouter()
        // 无 Provider、无 openWindow 动作：不应崩溃，只记录错误。
        router.openSettings(entryID: "general")
        XCTAssertTrue(router.didOpenSettingsWindow)
        XCTAssertEqual(router.lastOpenedEntryID, "general")
    }

    // MARK: - 通知监听

    func testStartObservingNotificationsIsIdempotent() {
        let router = SettingsWindowRouter()
        router.startObservingNotifications()
        // 重复调用不应重复订阅（否则一次请求会被处理多次）。
        router.startObservingNotifications()
        XCTAssertTrue(router.didOpenSettingsWindow == false)
    }

    func testOpenSettingsNotificationTriggersRouter() async throws {
        let router = SettingsWindowRouter()
        let provider = MockSettingViewProviding(
            entries: [makeEntry("database", title: "数据库", order: 40)]
        )
        router.attach(settingViewProvider: provider)
        router.startObservingNotifications()

        NotificationCenter.default.post(
            name: SettingViewNavigation.openSettingsNotification,
            object: nil,
            userInfo: [SettingViewNavigation.entryIDUserInfoKey: "database"]
        )

        // 通知走主队列，给路由宿主一次处理机会。
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertTrue(router.didOpenSettingsWindow, "监听设置通知后应能打开设置窗口")
        XCTAssertEqual(router.lastOpenedEntryID, "database")
        XCTAssertEqual(provider.selectedEntryID, "database", "通知携带的 entryID 应被选中")
    }

    func testOpenSettingsNotificationWithoutEntryIDOpensWindow() async throws {
        let router = SettingsWindowRouter()
        router.startObservingNotifications()

        NotificationCenter.default.post(
            name: SettingViewNavigation.openSettingsNotification,
            object: nil
        )

        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertTrue(router.didOpenSettingsWindow)
        XCTAssertNil(router.lastOpenedEntryID)
    }

    // MARK: - 窗口路由

    func testOpenWindowWithSettingsIDDelegatesToOpenSettings() {
        let router = SettingsWindowRouter()
        let provider = MockSettingViewProviding(
            entries: [makeEntry("store", title: "商店", order: 30)]
        )
        router.attach(settingViewProvider: provider)

        router.openWindow(windowID: ShellWindowID.settings, entryID: "store")

        XCTAssertEqual(provider.selectedEntryID, "store")
        XCTAssertTrue(router.didOpenSettingsWindow)
    }

    func testOpenWindowWithUnknownIDIsSafe() {
        let router = SettingsWindowRouter()
        router.openWindow(windowID: "no-such-window", entryID: nil)
        // 未知窗口不应触发设置窗口路由。
        XCTAssertFalse(router.didOpenSettingsWindow)
    }
}
