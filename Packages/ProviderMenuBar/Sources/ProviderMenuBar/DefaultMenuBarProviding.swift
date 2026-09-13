import Combine
import SwiftUI

/// Factory 注册的默认菜单栏贡献仓库。
@MainActor
public final class DefaultMenuBarProviding: ObservableObject, MenuBarProviding {
    @Published public private(set) var contentItems: [MenuBarContribution] = []
    @Published public private(set) var popupItems: [MenuBarContribution] = []

    public init() {}

    public func addContent(_ contribution: MenuBarContribution) {
        guard !contentItems.contains(where: { $0.id == contribution.id }) else { return }
        contentItems.append(contribution)
        contentItems = sorted(contentItems)
    }

    public func addPopup(_ contribution: MenuBarContribution) {
        guard !popupItems.contains(where: { $0.id == contribution.id }) else { return }
        popupItems.append(contribution)
        popupItems = sorted(popupItems)
    }

    public func removeItems(ownedBy pluginID: String) {
        contentItems.removeAll { $0.ownerPluginID == pluginID }
        popupItems.removeAll { $0.ownerPluginID == pluginID }
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
}
