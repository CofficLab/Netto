import Combine
import LumiUI
import ProviderShell
import SwiftUI

/// 菜单栏弹窗的 Toast 呈现器。
///
/// `ShellCenter.post` 只记录消息，不负责展示；弹窗没有可承载提示的宿主层，
/// 因此由呈现器持有当前提示并在到期后自动收起。
@MainActor
final class ToastPresenter: ObservableObject {
    /// 当前展示的提示；nil 表示没有提示。
    @Published private(set) var message: ToastMessage?

    private var dismissTask: Task<Void, Never>?

    /// 展示一条提示（到期后自动收起）。
    func present(_ message: ToastMessage?) {
        guard let message else { return }
        dismissTask?.cancel()
        self.message = message
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(message.duration))
            guard !Task.isCancelled else { return }
            self?.message = nil
        }
    }

    /// 立即收起当前提示。
    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        message = nil
    }

    /// 消费 Toast 流并依次展示。
    func observe(_ stream: AsyncStream<ToastMessage>) async {
        for await message in stream {
            present(message)
        }
    }
}

/// 菜单栏弹窗底部的提示条。
struct MenuBarToastOverlay: View {
    @ObservedObject var presenter: ToastPresenter

    var body: some View {
        if let message = presenter.message {
            AppStatusBanner(
                kind: message.isError ? .error : .success,
                title: message.description
            )
            .transition(.opacity)
            .accessibilityIdentifier("netpause.menubar.toast")
        }
    }
}
