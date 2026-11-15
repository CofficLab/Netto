import XCTest

/// UI coverage for Netto's primary menu-bar + main-window workflow.
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

    /// 仪表盘在主窗口中（启动即打开）；这里只等待它出现。
    @discardableResult
    func openDashboard(in app: XCUIApplication) -> XCUIElement {
        let dashboard = element(in: app, identifier: "netto.dashboard")
        XCTAssertTrue(dashboard.waitForExistence(timeout: 30), "Main window dashboard did not appear")
        return dashboard
    }

    /// 点击状态栏图标打开紧凑面板。
    @discardableResult
    func openMenuBarPanel(in app: XCUIApplication) -> XCUIElement {
        let statusItem = app.statusItems.matching(identifier: "netto.menu-bar").firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 20), "Menu-bar status item was not installed")
        statusItem.click()

        let panel = element(in: app, identifier: "netto.menubar.firewall")
        XCTAssertTrue(panel.waitForExistence(timeout: 10), "Menu-bar panel did not appear")
        return panel
    }

    func element(in app: XCUIApplication, containing text: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text))
            .firstMatch
    }
}
