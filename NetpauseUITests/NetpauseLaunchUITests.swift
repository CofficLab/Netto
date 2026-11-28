import XCTest

/// 启动与状态栏：无主窗口、菜单栏条目安装、弹窗展开/收起。
final class NetpauseLaunchUITests: NetpauseUITestBase {
    func testLaunchDoesNotOpenMainWindow() {
        let app = launchApp()

        XCTAssertFalse(
            app.windows.matching(NSPredicate(format: "title == %@", "Netpause")).firstMatch
                .waitForExistence(timeout: 3),
            "Menu-bar-only build should not open the Netpause main window"
        )
        XCTAssertFalse(
            element(in: app, identifier: "netpause.apps.list").waitForExistence(timeout: 2),
            "Dashboard should stay inside the menu-bar popover"
        )
        XCTAssertNotEqual(app.state, .notRunning)
    }

    func testLaunchInstallsMenuBarStatusItem() {
        let app = launchApp()
        let statusItem = app.statusItems.matching(identifier: "netpause.menu-bar").firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 20))
        XCTAssertNotEqual(app.state, .notRunning)
    }

    func testStatusItemOpensDashboardPanel() {
        let app = launchApp()
        _ = openMenuBarPanel(in: app)

        XCTAssertTrue(element(in: app, identifier: "netpause.menubar.settings").exists)
        XCTAssertTrue(element(in: app, identifier: "netpause.menubar.quit").exists)
        XCTAssertFalse(
            element(in: app, identifier: "netpause.menubar.open-main").exists,
            "Menu-bar-only build should not expose an open-main entry"
        )
        // 扩展未就绪时列表被引导替代，两种状态都属于面板正常展开。
        XCTAssertTrue(
            element(in: app, identifier: "netpause.dashboard.filter").exists
                || element(in: app, identifier: "netpause.firewall.guide").exists
        )
    }

    func testStatusItemCanClosePanel() {
        let app = launchApp()
        _ = openMenuBarPanel(in: app)
        let statusItem = app.statusItems.matching(identifier: "netpause.menu-bar").firstMatch
        statusItem.click()
        XCTAssertFalse(element(in: app, identifier: "netpause.menubar.firewall").waitForExistence(timeout: 2))
    }
}