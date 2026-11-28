import XCTest

/// UI coverage for Netpause's menu-bar-only workflow.
///
/// Tests only inspect or change local presentation state. They intentionally do
/// not install/enable the system extension, change firewall rules, or purchase
/// Store products because those actions affect the host machine/account.
@MainActor
class NetpauseUITestBase: XCTestCase {
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
            "-netpause-open-settings",
        ]
        app.launch()
        return app
    }

    func element(in app: XCUIApplication, identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// 主界面在菜单栏弹窗里；打开面板并等待仪表盘列表出现。
    ///
    /// 系统扩展未激活时弹窗只展示引导视图，列表不存在；此时跳过依赖
    /// 列表的用例，而不是把合法的新用户状态判为失败。
    @discardableResult
    func openDashboard(in app: XCUIApplication) throws -> XCUIElement {
        _ = openMenuBarPanel(in: app)
        if element(in: app, identifier: "netpause.firewall.guide").waitForExistence(timeout: 3) {
            throw XCTSkip("系统扩展未就绪，仪表盘列表不可用")
        }
        let dashboard = element(in: app, identifier: "netpause.apps.list")
        XCTAssertTrue(dashboard.waitForExistence(timeout: 20), "Menu-bar dashboard did not appear")
        return dashboard
    }

    /// 点击状态栏图标打开菜单栏弹窗。
    ///
    /// 启动参数会先弹出设置窗口，状态项首次点击偶尔被窗口前台化吞掉；
    /// 短暂等待后补点一次，避免测试因启动时序抖动而失败。
    @discardableResult
    func openMenuBarPanel(in app: XCUIApplication) -> XCUIElement {
        let statusItem = app.statusItems.matching(identifier: "netpause.menu-bar").firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 20), "Menu-bar status item was not installed")
        let panel = element(in: app, identifier: "netpause.menubar.firewall")

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