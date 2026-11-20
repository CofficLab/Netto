import AppKit
import Foundation

/// 菜单栏弹窗的呈现会话。
///
/// 弹窗的内容窗口在多次打开之间会被复用，选中应用如果保存在应用级共享
/// 状态上，关闭再打开就会停在上一次的应用详情。选中状态必须属于「本次
/// 呈现」：弹窗窗口离屏（关闭）时结束会话并复位选中状态。
@MainActor
final class PopoverPresentationSession {
    /// 窗口离屏通知（AppKit 未在 Swift 中导出该常量名）。
    static let willOrderOffScreen = Notification.Name("NSWindowWillOrderOffScreenNotification")

    /// 弹窗内容所在的窗口。
    private weak var window: NSWindow?

    /// 会话结束回调（复位选中应用）。
    var onEnd: (() -> Void)?

    private let notificationCenter: NotificationCenter
    /// 观察者 token 需要在非隔离析构里移除。
    nonisolated(unsafe) private var observerToken: NSObjectProtocol?

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        observerToken = notificationCenter.addObserver(
            forName: Self.willOrderOffScreen,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // 通知在主线程投递，窗口标识是可跨隔离传递的值。
            guard let object = notification.object as? NSWindow else { return }
            let identifier = ObjectIdentifier(object)
            MainActor.assumeIsolated {
                self?.handleWindowOffScreen(identifier)
            }
        }
    }

    deinit {
        if let token = observerToken {
            notificationCenter.removeObserver(token)
        }
    }

    /// 记录弹窗窗口（视图挂载后回填）。
    func attach(window: NSWindow?) {
        self.window = window
    }

    /// 弹窗窗口离屏：结束本次呈现会话。
    func handleWindowOffScreen(_ identifier: ObjectIdentifier?) {
        guard let identifier,
              let window,
              ObjectIdentifier(window) == identifier else { return }
        guard identifier != nil else { return }
        onEnd?()
    }
}
