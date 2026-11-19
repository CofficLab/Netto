import XCTest

/// UI coverage for Netto's menu-bar-only workflow.
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
        // 菜单栏 App 正常启动没有窗口；XCUITest 对无窗口进程做深层 AX 枚举会
        // 无限递归，测试统一用宿主的设置窗参数保持一个窗口存在。
        app.launchArguments += [
            "-ApplePersistenceIgnoreState", "YES",
            "-netto-open-settings",
        ]
        app.launch()
        return app
    }

    func element(in app: XCUIApplication, identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// 主界面在菜单栏弹窗里；打开面板并等待仪表盘列表出现。
    @discardableResult
    func openDashboard(in app: XCUIApplication) -> XCUIElement {
        _ = openMenuBarPanel(in: app)
        let dashboard = element(in: app, identifier: "netto.apps.list")
        XCTAssertTrue(dashboard.waitForExistence(timeout: 20), "Menu-bar dashboard did not appear")
        return dashboard
    }

    /// 点击状态栏图标打开菜单栏弹窗。
    ///
    /// 启动参数会先弹出设置窗口，状态项首次点击偶尔被窗口前台化吞掉；
    /// 短暂等待后补点一次，避免测试因启动时序抖动而失败。
    @discardableResult
    func openMenuBarPanel(in app: XCUIApplication) -> XCUIElement {
        let statusItem = app.statusItems.matching(identifier: "netto.menu-bar").firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 20), "Menu-bar status item was not installed")
        let panel = element(in: app, identifier: "netto.menubar.firewall")

        statusItem.click()
        if !panel.waitForExistence(timeout: 5) {
            statusItem.click()
        }
        XCTAssertTrue(panel.waitForExistence(timeout: 10), "Menu-bar panel did not appear")
        return panel
    }

    func element(in app: XCUIApplication, containing text: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text))
            .firstMatch
    }
}