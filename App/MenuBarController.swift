import AppKit
import Combine
import FactoryNetto
import KernelCore
import MenuBarHostKit
import ProviderMenuBar
import SwiftUI

/// AppKit owns the system status item and popover; packages contribute the views.
@MainActor
final class MenuBarController: NSObject, MenuBarHosting {
    private let menuBarHost = MenuBarHost()
    private let statusModel = MenuBarStatusModel()

    func install(kernel: KernelCoreContainer, environment: AppEnvironment) {
        guard !menuBarHost.isInstalled else { return }
        guard let menuBar = kernel.resolveProvider(MenuBarProviding.self) else { return }

        menuBarHost.install(
            statusView: AnyView(MenuBarStatusContent(
                provider: menuBar,
                model: statusModel,
                isDebug: Self.isDebugBuild
            )),
            configuration: MenuBarHostConfiguration(
                popoverSizing: .fixedSize(NSSize(width: 640, height: 760)),
                accessibilityIdentifier: "netto.menu-bar",
                accessibilityLabel: "TravelMode 防火墙状态"
            )
        ) {
            AnyView(FactoryNetto.makeRootView(environment: environment) {
                FactoryNetto.makeMenuBarPopupView(
                    kernel: kernel,
                    environment: environment
                )
                .frame(width: 640, height: 760)
            })
        }
    }

    func updateDeniedApps(_ hasDeniedApps: Bool) {
        statusModel.hasDeniedApps = hasDeniedApps
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

@MainActor
private struct MenuBarStatusContent: View {
    let provider: any MenuBarProviding
    @ObservedObject var model: MenuBarStatusModel
    let isDebug: Bool
    @StateObject private var refreshModel: MenuBarRefreshModel

    init(provider: any MenuBarProviding, model: MenuBarStatusModel, isDebug: Bool) {
        self.provider = provider
        self.model = model
        self.isDebug = isDebug
        _refreshModel = StateObject(wrappedValue: MenuBarRefreshModel(provider: provider))
    }

    private var symbol: String {
        if model.hasDeniedApps {
            return isDebug ? "airplane.departure" : "network.badge.shield.half.filled"
        }
        return isDebug ? "airplane" : "checkmark.circle.fill"
    }

    var body: some View {
        let _ = refreshModel.revision
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .frame(width: 20, height: 20)
            provider.makeContentView()
                .fixedSize(horizontal: true, vertical: true)
        }
        .padding(.horizontal, 2)
        .frame(height: 22)
        .onAppear { refreshModel.resume() }
        .onDisappear { refreshModel.cancel() }
    }
}
