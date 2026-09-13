import SwiftUI

// MARK: - Setting Entry Item

/// 设置入口项（由插件注入）。
///
/// 复刻 Lumi `ProviderSettingView.SettingEntryItem`：在设置窗口左侧侧边栏
/// 显示一个入口（标题 + SF Symbol），点击切换右侧详情视图。
///
/// 线程/actor：`@MainActor`（视图闭包在主线程渲染）。
@MainActor
public struct SettingEntryItem: Identifiable {
    /// 稳定入口 ID（全局唯一；重复注册去重保留先注册者）。
    public let id: String
    /// 侧边栏标题。
    public let title: String
    /// 侧边栏 SF Symbol 名。
    public let systemImage: String
    /// 排序（升序）。
    public var order: Int
    /// 右侧详情视图。
    public let makeDetailView: @MainActor () -> AnyView

    public init<Content: View>(
        id: String,
        title: String,
        systemImage: String,
        order: Int = 200,
        @ViewBuilder detail: @escaping @MainActor () -> Content
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.order = order
        self.makeDetailView = { AnyView(detail()) }
    }
}

// MARK: - Navigation

/// 打开设置窗口并定位到指定入口的深链契约。
///
/// 窗口归属 App 宿主，选中入口归属设置 Provider：通知让两层解耦，
/// 不丢失目标入口（复刻 Lumi `SettingViewNavigation`）。
public enum SettingViewNavigation {
    public static let openSettingsNotification = Notification.Name("netto.openSettings")
    public static let entryIDUserInfoKey = "netto.settings.entryID"
}

// MARK: - Events

/// 设置视图事件（Provider 状态变化通知）。
@MainActor
public enum SettingViewEvent {
    case entriesChanged
    case selectedEntryChanged(String?)
}

/// 观察句柄（onDisappear 时取消）。
@MainActor
public protocol SettingViewObserverHandle: AnyObject {
    func cancel()
}

// MARK: - Providing

/// 设置视图提供能力协议。
///
/// 定义「Kernel → 设置窗口内容」的最小契约：宿主启动时通过内核解析
/// `SettingViewProviding`，拿到设置视图作为 `Window("设置")` 内容展示。
/// 插件通过 `registerEntries`（替换）/ `addEntries`（追加）注入侧边栏入口，
/// 实现负责渲染「左侧入口列表 + 右侧详情视图」。
///
/// 使用 `AnyView` 而非 `associatedtype`：协议可无泛型约束地作为存在类型
/// 注册进 KernelCore 的 `[ObjectIdentifier: Any]` 注册表。
///
/// 继承 `Sendable`：KernelCore 的 `registerProvider` 要求 `P: Sendable`；
/// `@MainActor` 实现类自动满足该约束。
@MainActor
public protocol SettingViewProviding: AnyObject, Sendable {
    @discardableResult
    func addSettingViewObserver(
        _ callback: @escaping (SettingViewEvent) -> Void
    ) -> any SettingViewObserverHandle

    /// 当前已注入的全部设置入口项。
    var entries: [SettingEntryItem] { get }

    /// 当前选中的设置入口；宿主可通过它执行设置页深链导航。
    var selectedEntryID: String? { get }

    /// 选中指定入口。
    func selectEntry(id: String?)

    /// 注入设置入口项（替换当前全部项）。
    func registerEntries(_ entries: [SettingEntryItem])

    /// 追加设置入口项（保留已有项；同 id 去重，保留先注册者）。
    func addEntries(_ entries: [SettingEntryItem])

    /// 按 id 撤回插件贡献的入口。
    func removeEntries(ids: Set<String>)

    /// 返回设置视图（基于已注入的入口渲染）。
    func makeSettingView() -> AnyView
}

public extension SettingViewProviding {
    /// 默认无选中入口；具体 Provider 通常会在注册入口后选中第一项。
    var selectedEntryID: String? { nil }

    /// 默认 no-op，兼容只提供静态设置内容的 Provider。
    func selectEntry(id: String?) {}

    /// 追加语义默认实现：合入已有入口并按 `order` 排序（同 id 去重，保留先注册者）。
    func addEntries(_ newEntries: [SettingEntryItem]) {
        var merged = entries
        for entry in newEntries where !merged.contains(where: { $0.id == entry.id }) {
            merged.append(entry)
        }
        registerEntries(merged)
    }

    func removeEntries(ids: Set<String>) {
        registerEntries(entries.filter { !ids.contains($0.id) })
    }
}
