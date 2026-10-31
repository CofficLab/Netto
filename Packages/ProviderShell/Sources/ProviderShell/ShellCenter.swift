import Combine
import Foundation

/// Shell 中心 —— 主窗口 UI 贡献的聚合宿主。
///
/// 由 Factory 在装配时创建一次并注册为 `ShellToolbarProviding` /
/// `SettingsProviding` / `WindowProviding` / `ToastProviding` 的实现；
/// 各插件通过 Kernel 解析本实例登记贡献，Kernel 同时持有对应撤回 Token。
///
/// 线程/actor：`@MainActor`；全部贡献集合为 `@Published`，供 Host 视图观察，
/// 但**不做**全量状态广播（Kernel 不依赖本类）。
@MainActor
public final class ShellCenter: ObservableObject,
    ShellToolbarProviding,
    SettingsProviding,
    WindowProviding,
    WindowRoutingProviding,
    ToastProviding
{
    /// 工具栏贡献：ID → 贡献。
    @Published private var toolbarByID: [String: ToolbarContribution] = [:]

    /// 设置入口：ID → 入口。
    @Published private var settingsByID: [String: SettingsEntry] = [:]

    /// 当前插件窗口内容。
    @Published public private(set) var currentContent: WindowContentContribution?

    /// 最近一次 Toast（Host 覆盖层展示）。
    @Published public private(set) var lastToast: ToastMessage?

    /// 最近一次窗口请求。
    @Published public private(set) var lastWindowRequest: WindowRequest?

    /// 最近一次请求选中的设置入口 ID（深链）。
    ///
    /// 宿主在打开设置窗口前用它调用 `SettingViewProviding.selectEntry(id:)`，
    /// 保证窗口首次呈现就落在目标入口上。
    @Published public private(set) var lastSettingsEntryID: String?

    /// Host 注入的窗口打开回调（App 侧在装配时设置）。
    public var onRequestOpen: (@MainActor (WindowRequest) -> Void)?

    /// Toast 观察续流。
    private var toastContinuation: AsyncStream<ToastMessage>.Continuation?

    public init() {}

    // MARK: - ShellToolbarProviding

    public var leftContributions: [ToolbarContribution] {
        sorted(Array(toolbarByID.values), position: .left)
    }

    public var centerContributions: [ToolbarContribution] {
        sorted(Array(toolbarByID.values), position: .center)
    }

    public var rightContributions: [ToolbarContribution] {
        sorted(Array(toolbarByID.values), position: .right)
    }

    public func registerToolbar(_ contribution: ToolbarContribution) {
        toolbarByID[contribution.id] = contribution
    }

    public func removeToolbar(ownedBy pluginID: String) {
        toolbarByID = toolbarByID.filter { $0.value.ownerPluginID != pluginID }
    }

    public func removeToolbar(id: String) {
        toolbarByID.removeValue(forKey: id)
    }

    // MARK: - SettingsProviding

    public var entries: [SettingsEntry] {
        settingsByID.values.sorted { $0.order < $1.order }
    }

    public func registerEntry(_ entry: SettingsEntry) {
        settingsByID[entry.id] = entry
    }

    public func removeEntries(ownedBy pluginID: String) {
        settingsByID = settingsByID.filter { $0.value.ownerPluginID != pluginID }
    }

    // MARK: - WindowProviding

    public func requestOpen(_ request: WindowRequest) {
        lastWindowRequest = request
        onRequestOpen?(request)
    }

    public func registerContent(_ content: WindowContentContribution) {
        currentContent = content
    }

    public func removeContent(ownedBy pluginID: String) {
        if currentContent?.ownerPluginID == pluginID {
            currentContent = nil
        }
    }

    public func hideWindow() {
        currentContent = nil
    }

    // MARK: - WindowRoutingProviding

    /// 打开设置窗口。
    ///
    /// 深链入口在**打开之前**先选中，保证窗口首次呈现时右侧就是目标页面
    /// （否则会短暂显示旧入口再跳转）。
    public func openSettings(_ request: SettingsOpenRequest) {
        if let entryID = request.entryID {
            lastSettingsEntryID = entryID
        }
        requestOpen(WindowRequest(
            windowID: ShellWindowID.settings,
            title: ShellWindowTitle.settings,
            entryID: request.entryID
        ))
    }

    /// 打开指定 ID 的窗口。
    public func openWindow(windowID: String, entryID: String?) {
        if windowID == ShellWindowID.settings {
            openSettings(SettingsOpenRequest(entryID: entryID))
            return
        }
        requestOpen(WindowRequest(
            windowID: windowID,
            title: ShellWindowTitle.plugin,
            entryID: entryID
        ))
    }

    // MARK: - ToastProviding

    public func post(_ message: ToastMessage) {
        lastToast = message
        toastContinuation?.yield(message)
    }

    /// 观察 Toast 流（每订阅一个独立 AsyncStream，退订自动结束）。
    public func observeToasts() -> AsyncStream<ToastMessage> {
        AsyncStream { continuation in
            toastContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.toastContinuation = nil
                }
            }
        }
    }

    // MARK: - Private

    private func sorted(_ contributions: [ToolbarContribution], position: ToolbarPosition) -> [ToolbarContribution] {
        contributions
            .filter { $0.position == position }
            .sorted { $0.order < $1.order }
    }
}
