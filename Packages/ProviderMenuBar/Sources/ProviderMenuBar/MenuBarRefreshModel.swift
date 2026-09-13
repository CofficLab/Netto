import Combine

/// 把 Provider 的贡献事件桥接成 SwiftUI 可观察状态。
///
/// AppKit/SwiftUI Host 持有此模型，从而只跟随菜单栏 Provider 的变更刷新，
/// 不需要让 Kernel 或具体 Provider 实现参与视图更新。
@MainActor
public final class MenuBarRefreshModel: ObservableObject {
    @Published public private(set) var revision = 0

    private let provider: any MenuBarProviding
    private var observer: (any MenuBarObserverHandle)?

    public init(provider: any MenuBarProviding) {
        self.provider = provider
        resume()
    }

    public func resume() {
        guard observer == nil else { return }
        observer = provider.addMenuBarObserver { [weak self] _ in
            self?.revision &+= 1
        }
    }

    public func cancel() {
        observer?.cancel()
        observer = nil
    }
}
