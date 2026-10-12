import XCTest

/// UI coverage for Netto's primary menu-bar workflow.
///
/// Tests only inspect or change local presentation state. They intentionally do
/// not install/enable the system extension, change firewall rules, or purchase
/// Store products because those actions affect the host machine/account.
@MainActor
class NettoUITestBase: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        // 禁用 macOS 窗口/弹出层状态恢复，避免上一次运行的残留状态干扰测试。
        app.launchArguments += ["-ApplePersistenceIgnoreState", "YES"]
        app.launch()
        return app
    }

    func element(in app: XCUIApplication, identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @discardableResult
    func openDashboard(in app: XCUIApplication) -> XCUIElement {
        let statusItem = app.statusItems.matching(identifier: "netto.menu-bar").firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 20), "Menu-bar status item was not installed")
        // 弹窗可能残留自上一次测试，先关闭再打开，保证状态干净。
        if element(in: app, identifier: "netto.dashboard").waitForExistence(timeout: 2) {
            statusItem.click()
        }
        statusItem.click()

        let dashboard = element(in: app, identifier: "netto.dashboard")
        XCTAssertTrue(dashboard.waitForExistence(timeout: 20), "Dashboard popover did not appear")
        return dashboard
    }

    func element(in app: XCUIApplication, containing text: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text))
            .firstMatch
    }
}
