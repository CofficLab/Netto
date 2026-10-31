import Combine
import ProviderSettingView
import SwiftUI

/// 设置视图刷新触发器（可观察对象）。
///
/// 上游 `SettingViewProviding` 的默认实现不是 `ObservableObject`，因此
/// `selectedEntryID` 的变化**不会**让 SwiftUI 自动重算。本触发器把变更
/// 事件转换成一次 `@Published` 变更，供桥接视图读取。
@MainActor
final class SettingsViewRefreshTrigger: ObservableObject {
    /// 变更计数（每次入口/条目变更自增）。
    @Published private(set) var revision: Int = 0

    /// 观察句柄。
    private var observerHandle: (any SettingViewObserverHandle)?

    /// 设置视图契约。
    private let provider: any SettingViewProviding

    init(provider: any SettingViewProviding) {
        self.provider = provider
    }

    /// 开始订阅变更事件。
    func start() {
        guard observerHandle == nil else { return }
        observerHandle = provider.addSettingViewObserver { [weak self] _ in
            self?.revision += 1
        }
    }

    /// 停止订阅。
    func stop() {
        observerHandle?.cancel()
        observerHandle = nil
    }
}

/// 设置视图刷新桥 —— 让上游 `SettingView` 能响应「选中入口」变化。
///
/// ## 为什么需要它
///
/// 上游 LumiSettings 的 `SettingView` 有两个叠加的问题，导致**点击左侧入口
/// 后右侧详情视图不刷新**：
///
/// 1. `provider` 是普通类（`DefaultSettingViewProviding` 不是
///    `ObservableObject`），视图读取 `provider.selectedEntryID` **不会**
///    触发 SwiftUI 重算；
/// 2. 它自己的 `@State observationRevision` 在 `onAppear` 的观察回调里
///    自增，却**从未在 `body` 中被读取**（没有 `let _ = observationRevision`），
///    因此这个自增不会让 `body` 重算 —— 观察回调形同虚设。
///
/// 实测（最小复现）：`@State` 自增但 `body` 不读取 → 视图不刷新；
/// `body` 里读取该状态 → 视图刷新；父级读取 + `.id()` 强制重建 →
/// 内层视图也会用新值重算。
///
/// ## 本桥的做法
///
/// 宿主侧订阅 `SettingViewProviding` 的变更事件，自增一个**会被 `body`
/// 读取**的可观察计数，并用 `.id(revision)` 强制重建内部设置视图 —— 让
/// 新鲜的 `provider.selectedEntryID` 参与求值。
///
/// `.id()` 会重建整棵设置视图子树（滚动位置等瞬时状态会重置），
/// 对设置窗口而言这是可接受的代价：入口切换本就是页面级跳转。
///
/// ## 线程/actor
///
/// `@MainActor`：观察与视图更新都在主线程。
@MainActor
struct SettingsViewRefreshBridge<Content: View>: View {
    /// 设置视图契约（用于订阅变更事件）。
    let provider: any SettingViewProviding

    /// 设置视图内容。
    let content: Content

    /// 刷新触发器（可观察；`body` 读取 `revision` 以触发重算）。
    @StateObject private var trigger: SettingsViewRefreshTrigger

    init(provider: any SettingViewProviding, @ViewBuilder content: () -> Content) {
        self.provider = provider
        self.content = content()
        _trigger = StateObject(wrappedValue: SettingsViewRefreshTrigger(provider: provider))
    }

    var body: some View {
        // 关键：读取 `revision` 才会让本视图因变更事件重算。
        let _ = trigger.revision

        content
            .id(trigger.revision)
            .onAppear(perform: trigger.start)
            .onDisappear(perform: trigger.stop)
    }
}
