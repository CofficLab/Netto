import Foundation
import ProviderShell
import Testing
@testable import PluginFirewallDashboard

/// 菜单栏弹窗的操作反馈：ShellCenter 投递的提示必须能在弹窗内被看到。
@MainActor
@Suite("弹窗操作反馈")
struct MenuBarToastTests {

    @Test("ShellCenter 投递的提示会展示在弹窗中")
    func toastIsPresented() async throws {
        let shell = ShellCenter()
        let presenter = ToastPresenter()
        let task = Task { await presenter.observe(shell.observeToasts()) }
        defer { task.cancel() }

        try await Task.sleep(for: .milliseconds(50))
        shell.post(ToastMessage(description: "已禁止"))

        try await waitUntil { presenter.message?.description == "已禁止" }
    }

    @Test("新提示替换旧提示")
    func newToastReplacesPrevious() async throws {
        let presenter = ToastPresenter()

        presenter.present(ToastMessage(description: "已禁止"))
        presenter.present(ToastMessage(description: "已允许"))

        #expect(presenter.message?.description == "已允许")
    }

    @Test("提示到期后自动收起")
    func toastAutoDismisses() async throws {
        let presenter = ToastPresenter()

        presenter.present(ToastMessage(description: "已导出到下载目录", duration: 0))
        try await waitUntil { presenter.message == nil }
    }

    @Test("错误提示保留错误标记")
    func errorToastKeepsErrorFlag() {
        let presenter = ToastPresenter()

        presenter.present(ToastMessage(description: "开启防火墙失败", isError: true))

        #expect(presenter.message?.isError == true)
    }

    private func waitUntil(
        timeout: TimeInterval = 3,
        _ condition: @MainActor () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        Issue.record("等待条件超时")
    }
}
