import Foundation
import SwiftUI

/// `SettingViewProviding` 的默认实现：持有注入的 `SettingEntryItem`，
/// 渲染为「左侧入口列表 + 右侧详情视图」的设置界面。
///
/// 复刻 Lumi `DefaultSettingViewProviding`：
/// - 入口按 `order` 排序；注册后默认选中第一项（保持当前选中）。
/// - 状态变化通过 observer 通知（`SettingViewEvent`）驱动视图刷新。
///
/// 线程/actor：`@MainActor`（全部状态与回调在主线程）。
@MainActor
public final class DefaultSettingViewProviding: SettingViewProviding {
    public private(set) var entries: [SettingEntryItem] = []
    public private(set) var selectedEntryID: String?
    private var observers: [UUID: (SettingViewEvent) -> Void] = [:]

    public init() {}

    @discardableResult
    public func addSettingViewObserver(
        _ callback: @escaping (SettingViewEvent) -> Void
    ) -> any SettingViewObserverHandle {
        let id = UUID()
        observers[id] = callback
        return ObserverHandle { [weak self] in
            self?.observers.removeValue(forKey: id)
        }
    }

    public func registerEntries(_ entries: [SettingEntryItem]) {
        let previousSelectedEntryID = selectedEntryID
        self.entries = entries.sorted { $0.order < $1.order }
        // 保持当前选中；若为空或已失效则默认选中第一个。
        if selectedEntryID == nil || !self.entries.contains(where: { $0.id == selectedEntryID }) {
            selectedEntryID = self.entries.first?.id
        }
        notify(.entriesChanged)
        if previousSelectedEntryID != selectedEntryID {
            notify(.selectedEntryChanged(selectedEntryID))
        }
    }

    public func selectEntry(id: String?) {
        guard selectedEntryID != id else { return }
        selectedEntryID = id
        notify(.selectedEntryChanged(id))
    }

    public func makeSettingView() -> AnyView {
        AnyView(SettingView(provider: self))
    }

    private func notify(_ event: SettingViewEvent) {
        observers.values.forEach { $0(event) }
    }

    private final class ObserverHandle: SettingViewObserverHandle {
        private var cancellation: (() -> Void)?

        init(cancellation: @escaping () -> Void) {
            self.cancellation = cancellation
        }

        func cancel() {
            cancellation?()
            cancellation = nil
        }
    }
}
