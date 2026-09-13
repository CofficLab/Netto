import FactoryNetto
import SwiftUI

/// App Target 只持有 AppKit 宿主并将场景交给 Factory。
@main
struct TheApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let menuBarController: MenuBarController
    private let scenes: NettoAppScenes

    init() {
        let environment = FactoryNetto.makeAppEnvironment()
        let menuBarController = MenuBarController()
        self.menuBarController = menuBarController
        self.scenes = FactoryNetto.makeAppScenes(environment: environment)

        Task {
            await environment.bootstrap(menuBarHost: menuBarController)
        }
    }

    var body: some Scene {
        scenes
    }
}
