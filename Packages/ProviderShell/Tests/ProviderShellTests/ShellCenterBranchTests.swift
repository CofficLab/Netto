import Foundation
import SwiftUI
import XCTest
@testable import ProviderShell

/// ShellCenter 的窗口内容归属撤回与 Toast 便捷方法测试。
///
/// 既有 `ShellCenterTests` 覆盖工具栏/设置排序、按 owner 撤回、
/// 窗口请求回调与 Toast 流投递；本文件补齐剩余分支。
@MainActor
final class ShellCenterBranchTests: XCTestCase {

    // MARK: - 窗口内容归属

    func testRemoveContentClearsContentOwnedByPlugin() {
        let center = ShellCenter()
        center.registerContent(WindowContentContribution(
            id: "w-store",
            title: "Store",
            ownerPluginID: "Store"
        ) {
            AnyView(EmptyView())
        })
        XCTAssertEqual(center.currentContent?.id, "w-store")

        center.removeContent(ownedBy: "Store")

        // owner 匹配时当前窗口内容被清空。
        XCTAssertNil(center.currentContent)
    }

    func testRemoveContentKeepsContentOfOtherPlugin() {
        let center = ShellCenter()
        center.registerContent(WindowContentContribution(
            id: "w-store",
            title: "Store",
            ownerPluginID: "Store"
        ) {
            AnyView(EmptyView())
        })

        center.removeContent(ownedBy: "Other")

        XCTAssertEqual(center.currentContent?.id, "w-store")
    }

    func testHideWindowClearsContent() {
        let center = ShellCenter()
        center.registerContent(WindowContentContribution(
            id: "w-store",
            title: "Store",
            ownerPluginID: "Store"
        ) {
            AnyView(EmptyView())
        })

        center.hideWindow()

        XCTAssertNil(center.currentContent)
    }

    // MARK: - Toast 便捷方法

    func testPostSuccessProducesNonErrorToast() {
        let center = ShellCenter()

        center.postSuccess("已保存")

        XCTAssertEqual(center.lastToast?.description, "已保存")
        XCTAssertEqual(center.lastToast?.isError, false)
        XCTAssertEqual(center.lastToast?.duration, 3)
        XCTAssertEqual(center.lastToast?.channel, "default")
    }

    func testPostErrorProducesErrorToast() {
        let center = ShellCenter()

        center.postError("保存失败")

        XCTAssertEqual(center.lastToast?.description, "保存失败")
        XCTAssertEqual(center.lastToast?.isError, true)
        XCTAssertEqual(center.lastToast?.duration, 3)
        XCTAssertEqual(center.lastToast?.channel, "default")
    }

    func testToastMessageUsesCustomDurationAndChannel() {
        let center = ShellCenter()

        center.post(ToastMessage(description: "自定义", duration: 9, channel: "db"))

        XCTAssertEqual(center.lastToast?.duration, 9)
        XCTAssertEqual(center.lastToast?.channel, "db")
    }

    // MARK: - Toast 流终止

    func testToastStreamStopsDeliveringAfterCancellation() async throws {
        let center = ShellCenter()
        let task = Task { () -> [ToastMessage] in
            var messages: [ToastMessage] = []
            for await message in center.observeToasts() {
                messages.append(message)
            }
            return messages
        }
        // 等待订阅建立。
        try? await Task.sleep(for: .milliseconds(100))

        center.post(ToastMessage(description: "one"))
        try? await Task.sleep(for: .milliseconds(100))
        task.cancel()
        try? await Task.sleep(for: .milliseconds(100))

        // 订阅已结束（continuation 被清空），新 Toast 不再投递给旧订阅者。
        center.post(ToastMessage(description: "two"))
        try? await Task.sleep(for: .milliseconds(100))

        let messages = await task.value
        XCTAssertEqual(messages.map(\.description), ["one"])
        // 最后一条 Toast 仍会被记录。
        XCTAssertEqual(center.lastToast?.description, "two")
    }

    func testNewSubscriberReceivesToastsAfterPreviousStreamEnded() async throws {
        let center = ShellCenter()
        let first = Task { () -> [ToastMessage] in
            var messages: [ToastMessage] = []
            for await message in center.observeToasts() {
                messages.append(message)
            }
            return messages
        }
        try? await Task.sleep(for: .milliseconds(100))
        first.cancel()
        try? await Task.sleep(for: .milliseconds(100))

        // 重新订阅会建立新的 continuation。
        let second = Task { () -> [ToastMessage] in
            var messages: [ToastMessage] = []
            for await message in center.observeToasts() {
                messages.append(message)
            }
            return messages
        }
        try? await Task.sleep(for: .milliseconds(100))
        center.post(ToastMessage(description: "again"))
        try? await Task.sleep(for: .milliseconds(100))
        second.cancel()

        let messages = await second.value
        XCTAssertEqual(messages.map(\.description), ["again"])
    }
}
