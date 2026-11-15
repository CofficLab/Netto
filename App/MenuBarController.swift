import AppKit
import FactoryNetto
import KernelCore
import MenuBarHostKit
import ProviderShell
import SwiftUI

/// AppKit 持有系统状态项与 popover；菜单栏内容全部由插件贡献。
///
/// 状态栏图标 = 品牌 Logo + `MenuBarProviding.contentItems`；
/// popover = 紧凑面板（`popupItems` + 宿主动作行），由 Factory 装配。
@MainActor
final class MenuBarController: NSObject, MenuBarHosting {
    private let menuBarHost = MenuBarHost()

    func install(kernel: KernelCoreContainer, environment: AppEnvironment) {
        guard !menuBarHost.isInstalled else { return }

        menuBarHost.install(
            statusView: FactoryNetto.makeStatusBarView(
                kernel: kernel,
                brandImage: Image("Logo")
            ),
            configuration: MenuBarHostConfiguration(
                statusViewHeight: 20,
                popoverSizing: .fixedWidth(300, maximumHeight: 800),
                accessibilityIdentifier: "netto.menu-bar",
                accessibilityLabel: "TravelMode",
                activatesApplication: true
            )
        ) { [weak self, environment] in
            // 外层 RootView 让面板在 Kernel 启动完成后自动切换到真实内容：
            // popover 内容只构建一次并缓存，直接解析 Provider 会把启动期的
            // nil 契约固化下来。
            AnyView(FactoryNetto.makeRootView(environment: environment) {
                FactoryNetto.makeMenuBarPopoverView(
                    kernel: kernel,
                    environment: environment,
                    onOpenMainWindow: { self?.openMainWindow(environment) },
                    onOpenSettings: { self?.openSettings(environment) },
                    onQuit: { NSApp.terminate(nil) }
                )
            })
        }
    }

    private func openMainWindow(_ environment: AppEnvironment) {
        menuBarHost.closePopover()
        environment.router.openWindow(windowID: ShellWindowID.main)
    }

    private func openSettings(_ environment: AppEnvironment) {
        menuBarHost.closePopover()
        environment.router.openSettings()
    }
}
