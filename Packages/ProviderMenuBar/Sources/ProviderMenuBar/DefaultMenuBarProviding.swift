import SwiftUI

/// Factory 注册的默认菜单栏贡献仓库。
@MainActor
public final class DefaultMenuBarProviding: MenuBarProviding {
    public private(set) var contentItems: [MenuBarContribution] = []
    public private(set) var popupItems: [MenuBarContribution] = []
    private var observers: [UUID: (MenuBarEvent) -> Void] = [:]

    public init() {}

    @discardableResult
    public func addMenuBarObserver(_ callback: @escaping (MenuBarEvent) -> Void) -> any MenuBarObserverHandle {
        let id = UUID()
        observers[id] = callback
        return ObserverHandle { [weak self] in
            self?.observers.removeValue(forKey: id)
        }
    }

    public func addContent(_ contribution: MenuBarContribution) {
        guard !contentItems.contains(where: { $0.id == contribution.id }) else { return }
        contentItems.append(contribution)
        contentItems = sorted(contentItems)
        notify(.contentItemsChanged)
    }

    public func addPopup(_ contribution: MenuBarContribution) {
        guard !popupItems.contains(where: { $0.id == contribution.id }) else { return }
        popupItems.append(contribution)
        popupItems = sorted(popupItems)
        notify(.popupItemsChanged)
    }

    public func removeItems(ownedBy pluginID: String) {
        let oldContentCount = contentItems.count
        let oldPopupCount = popupItems.count
        contentItems.removeAll { $0.ownerPluginID == pluginID }
        popupItems.removeAll { $0.ownerPluginID == pluginID }
        if contentItems.count != oldContentCount { notify(.contentItemsChanged) }
        if popupItems.count != oldPopupCount { notify(.popupItemsChanged) }
    }

    public func makeContentView() -> AnyView {
        AnyView(
            HStack(spacing: 4) {
                ForEach(contentItems) { contribution in
                    contribution.makeView().help(contribution.title)
                }
            }
        )
    }

    public func makePopupView() -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 0) {
                ForEach(popupItems) { contribution in
                    contribution.makeView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        )
    }

    private func sorted(_ items: [MenuBarContribution]) -> [MenuBarContribution] {
        items.sorted {
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.id < $1.id
        }
    }

    private func notify(_ event: MenuBarEvent) {
        Array(observers.values).forEach { $0(event) }
    }

    private final class ObserverHandle: MenuBarObserverHandle {
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
