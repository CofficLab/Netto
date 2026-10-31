import AppKit
import Combine
import Foundation
import OSLog
import ProviderSettingView
import ProviderShell
import SwiftUI

/// 设置窗口路由宿主 —— 把「打开某个窗口」的请求翻译成真实的窗口动作。
///
/// ## 为什么需要它
///
/// Netto 是 `LSUIElement` 菜单栏应用：启动时 `Group` 场景里只有**第一个**
/// `Window` 会自动呈现，其余场景需要 `openWindow(id:)` 主动打开。而
/// `openWindow` 是 SwiftUI 的**视图层**能力（`Environment`），只有视图
/// 才能拿到它。
///
/// 之前的实现把 `openWindow` 的捕获与 `openSettingsNotification` 的监听
/// 都放在**设置窗口自己的场景**（`SettingsWindowHost`）里 —— 而那个场景
/// 从不被创建，于是形成鸡生蛋死锁：想打开设置窗口，得先有设置窗口。
///
/// 本类把路由能力从「目标场景」挪到「**常驻宿主**」：
/// - `openWindow` 由启动时必定出现的欢迎窗口场景捕获并交给本类持有；
/// - `openSettingsNotification` 等通知的监听挂在本类上（生命周期 = App 生命周期）；
/// - `ShellCenter.onRequestOpen` 的绑定也移到这里；
/// - 窗口已存在时只前置，不新建（`Window` 场景本身是单例）。
///
/// ## 线程/actor
///
/// `@MainActor`：窗口操作与 AppKit 查询必须在主线程。
@MainActor
public final class SettingsWindowRouter: ObservableObject {
    /// 共享日志。
    private let logger = Logger(subsystem: "com.yueyi.TravelMode", category: "settings-window")

    /// 捕获到的 SwiftUI 窗口打开动作。
    ///
    /// 由**启动即存在的场景**（欢迎窗口）注入。实测该动作在源窗口关闭后
    /// 依然有效，可以打开一个从未创建过的场景。
    private var openWindowAction: OpenWindowAction?

    /// 设置视图契约（用于深链时校验入口 ID 并切换选中项）。
    private weak var settingViewProvider: (any SettingViewProviding)?

    /// 通知订阅句柄（生命周期与本类一致 = App 生命周期）。
    private var cancellables: Set<AnyCancellable> = []

    /// 设置窗口路由事件（供 UI 测试与诊断观察）。
    @Published public private(set) var lastOpenedEntryID: String?

    /// 设置窗口是否已被请求打开过（UI 测试可据此断言）。
    @Published public private(set) var didOpenSettingsWindow: Bool = false

    public init() {}

    // MARK: - 注入

    /// 注入 SwiftUI 的窗口打开动作。
    ///
    /// 必须在**启动即存在的场景**里调用（Netto 由欢迎窗口场景调用），
    /// 否则目标场景从不创建时永远拿不到这个动作。
    public func attach(openWindow: OpenWindowAction) {
        guard openWindowAction == nil else { return }
        openWindowAction = openWindow
        logger.info("已捕获窗口打开动作")
    }

    /// 注入设置视图契约（深链时用于校验与切换入口）。
    ///
    /// `nil` 不会覆盖已有值 —— 欢迎窗口的 `onAppear` 可能早于内核启动，
    /// 此时拿不到 Provider，不应把已绑定好的契约清成 `nil`。
    public func attach(settingViewProvider: (any SettingViewProviding)?) {
        guard let settingViewProvider else { return }
        self.settingViewProvider = settingViewProvider
    }

    /// 开始监听窗口路由通知。
    ///
    /// 由宿主（AppEnvironment bootstrap）调用一次。监听放在**常驻宿主**而
    /// 不是目标场景，是修复「鸡生蛋死锁」的关键：设置窗口从未创建时，
    /// 打开它的请求依然能被接收。
    public func startObservingNotifications() {
        guard cancellables.isEmpty else { return }

        // 打开设置窗口（可带 entryID 深链）。
        cancellables.insert(
            NotificationCenter.default
                .publisher(for: SettingViewNavigation.openSettingsNotification)
                .receive(on: RunLoop.main)
                .sink { [weak self] notification in
                    let entryID = notification.userInfo?[SettingViewNavigation.entryIDUserInfoKey] as? String
                    MainActor.assumeIsolated {
                        self?.openSettings(entryID: entryID)
                    }
                }
        )

        // 打开欢迎引导窗口。
        cancellables.insert(
            NotificationCenter.default
                .publisher(for: .shouldOpenWelcomeWindow)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    MainActor.assumeIsolated {
                        self?.openWelcomeWindow()
                    }
                }
        )

        // 允许/拒绝规则变化 → 刷新菜单栏指示灯（兼容保留的旧信号）。
        for name in [Notification.Name.firewallDidSetAllow, .firewallDidSetDeny] {
            cancellables.insert(
                NotificationCenter.default
                    .publisher(for: name)
                    .receive(on: RunLoop.main)
                    .sink { [weak self] _ in
                        MainActor.assumeIsolated {
                            self?.onAppRulesChanged?()
                        }
                    }
            )
        }
    }

    /// 应用允许/拒绝规则变化回调（由宿主注入，用于刷新菜单栏指示灯）。
    public var onAppRulesChanged: (() -> Void)?

    /// 打开欢迎窗口前的回调（由宿主注入，用于置位「展示引导内容」标记）。
    public var onRequestWelcomeContent: (() -> Void)?

    // MARK: - 路由

    /// 打开设置窗口（可选深链到某个入口）。
    ///
    /// 语义：
    /// 1. 深链入口先**校验**（入口必须存在）再**选中**；
    /// 2. 窗口已存在且可见 → 只前置（激活 App + `makeKeyAndOrderFront`）；
    /// 3. 窗口不存在或已关闭 → `openWindow(id:)` 重新呈现（不新建第二个窗口）。
    public func openSettings(entryID: String? = nil) {
        if let entryID {
            selectEntryIfPresent(entryID)
            lastOpenedEntryID = entryID
        } else {
            lastOpenedEntryID = nil
        }

        Self.activateApp()

        let existing = Self.findSettingsWindow()
        if let existing, existing.isVisible {
            // 已打开：只前置，不新建。
            existing.makeKeyAndOrderFront(nil)
            logger.info("设置窗口已存在，置前显示")
        } else if let openWindowAction {
            logger.info("打开设置窗口")
            openWindowAction(id: ShellWindowID.settings)
        } else if let existing {
            existing.makeKeyAndOrderFront(nil)
        } else {
            logger.error("缺少窗口打开动作，无法打开设置窗口")
        }
        didOpenSettingsWindow = true
    }

    /// 打开指定 ID 的窗口。
    public func openWindow(windowID: String, entryID: String? = nil) {
        if windowID == ShellWindowID.settings {
            openSettings(entryID: entryID)
            return
        }
        Self.activateApp()
        if let existing = Self.findWindow(id: windowID), existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        if let openWindowAction {
            openWindowAction(id: windowID)
        } else {
            logger.error("缺少窗口打开动作，无法打开窗口 \(windowID, privacy: .public)")
        }
    }

    /// 打开欢迎引导窗口。
    public func openWelcomeWindow() {
        Self.activateApp()
        onRequestWelcomeContent?()
        if let existing = Self.findWindow(id: ShellWindowID.welcome), existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        if let openWindowAction {
            openWindowAction(id: ShellWindowID.welcome)
        } else {
            logger.error("缺少窗口打开动作，无法打开欢迎窗口")
        }
    }

    // MARK: - 私有

    /// 选中入口（入口不存在时保持原选中项不变）。
    private func selectEntryIfPresent(_ entryID: String) {
        guard let provider = settingViewProvider else { return }
        guard provider.entries.contains(where: { $0.id == entryID }) else {
            logger.error("设置入口不存在，忽略深链 \(entryID, privacy: .public)")
            return
        }
        provider.selectEntry(id: entryID)
    }

    /// 激活 App（把焦点交给本应用）。
    ///
    /// `NSApp` 在**无 App 运行环境**下（如 SPM 单元测试）为 nil，
    /// 因此这里做空值保护 —— 路由逻辑不应因缺少宿主而崩溃。
    private static func activateApp() {
        NSApp?.activate(ignoringOtherApps: true)
    }

    /// 按 SwiftUI 场景 ID 定位窗口。
    ///
    /// SwiftUI 托管的 `NSWindow.identifier` 等于 Scene id（实测），比按标题
    /// 匹配更可靠（标题会被用户或系统改写）。
    private static func findWindow(id: String) -> NSWindow? {
        NSApp?.windows.first { $0.identifier?.rawValue == id }
    }

    /// 定位设置窗口（按 identifier，回退到标题匹配）。
    private static func findSettingsWindow() -> NSWindow? {
        if let window = findWindow(id: ShellWindowID.settings) {
            return window
        }
        return NSApp?.windows.first {
            $0.title == ShellWindowTitle.settings && $0.isVisible
        }
    }
}
