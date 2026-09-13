import AppKit
import Combine
import FactoryNetto
import KernelCore
import ProviderMenuBar
import SwiftUI

/// AppKit owns the system status item and popover; packages contribute the views.
@MainActor
final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var statusHostingView: MenuBarHostingView<MenuBarStatusContent>?
    private var popover: NSPopover?
    private let statusModel = MenuBarStatusModel()

    func install(kernel: KernelCoreContainer, environment: AppEnvironment) {
        guard statusItem == nil else { return }

        let menuBar = kernel.resolveProvider(MenuBarProviding.self) as? DefaultMenuBarProviding
            ?? DefaultMenuBarProviding()
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = item.button else { return }
        button.title = ""
        button.image = nil
        button.target = self
        button.action = #selector(togglePopover(_:))

        let hostedStatus = MenuBarHostingView(
            rootView: MenuBarStatusContent(
                provider: menuBar,
                model: statusModel,
                isDebug: Self.isDebugBuild
            )
        )
        hostedStatus.translatesAutoresizingMaskIntoConstraints = false
        button.subviews.forEach { $0.removeFromSuperview() }
        button.addSubview(hostedStatus)
        NSLayoutConstraint.activate([
            hostedStatus.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            hostedStatus.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            hostedStatus.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            hostedStatus.heightAnchor.constraint(equalToConstant: 22),
        ])

        let popup = NSPopover()
        popup.behavior = .transient
        popup.animates = true
        popup.contentSize = NSSize(width: 640, height: 760)
        popup.contentViewController = NSHostingController(
            rootView: RootView(environment: environment) {
                FactoryNetto.makeMenuBarPopupView(
                    kernel: kernel,
                    sessionStartDate: environment.sessionStartDate
                )
                .frame(width: 640, height: 760)
            }
        )

        statusItem = item
        statusHostingView = hostedStatus
        popover = popup
    }

    func updateDeniedApps(_ hasDeniedApps: Bool) {
        statusModel.hasDeniedApps = hasDeniedApps
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private static var isDebugBuild: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }
}

@MainActor
private final class MenuBarStatusModel: ObservableObject {
    @Published var hasDeniedApps = false
}

private final class MenuBarHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

@MainActor
private struct MenuBarStatusContent: View {
    @ObservedObject var provider: DefaultMenuBarProviding
    @ObservedObject var model: MenuBarStatusModel
    let isDebug: Bool

    private var symbol: String {
        if model.hasDeniedApps {
            return isDebug ? "airplane.departure" : "network.badge.shield.half.filled"
        }
        return isDebug ? "airplane" : "checkmark.circle.fill"
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .frame(width: 20, height: 20)
            provider.makeContentView()
                .fixedSize(horizontal: true, vertical: true)
        }
        .padding(.horizontal, 2)
        .frame(height: 22)
    }
}
