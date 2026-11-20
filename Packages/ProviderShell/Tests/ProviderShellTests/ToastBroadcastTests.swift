import XCTest
@testable import ProviderShell

/// Toast 广播：多个订阅者必须各自收到同一条提示。
@MainActor
final class ToastBroadcastTests: XCTestCase {

    func testMultipleSubscribersEachReceiveToast() async throws {
        let center = ShellCenter()
        let first = Task { () -> [String] in
            var messages: [String] = []
            for await message in center.observeToasts() {
                messages.append(message.description)
            }
            return messages
        }
        let second = Task { () -> [String] in
            var messages: [String] = []
            for await message in center.observeToasts() {
                messages.append(message.description)
            }
            return messages
        }
        try? await Task.sleep(for: .milliseconds(100))

        center.post(ToastMessage(description: "已禁止"))
        try? await Task.sleep(for: .milliseconds(100))
        first.cancel()
        second.cancel()

        let firstMessages = await first.value
        let secondMessages = await second.value
        XCTAssertEqual(firstMessages.map { $0 }, ["已禁止"])
        XCTAssertEqual(secondMessages.map { $0 }, ["已禁止"])
    }
}
