import XCTest

/// 启动与状态栏：无主窗口、菜单栏条目安装、弹窗展开/收起。
final class NettoLaunchUITests: NettoUITestBase {
    func testLaunchDoesNotOpenMainWindow() {
        let app = launchApp()

        XCTAssertFalse(
            app.windows.matching(NSPredicate(format: "title == %@", "TravelMode")).firstMatch
                .waitForExistence(timeout: 3),
            "Menu-bar-only build should not open the TravelMode main window"
        )
        XCTAssertFalse(
            element(in: app, identifier: "netto.apps.list").waitForExistence(timeout: 2),
            "Dashboard should stay inside the menu-bar popover"
        )
        XCTAssertNotEqual(app.state, .notRunning)
    }

    func testLaunchInstallsMenuBarStatusItem() {
        let app = launchApp()
        let statusItem = app.statusItems.matching(identifier: "netto.menu-bar").firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 20))
        XCTAssertNotEqual(app.state, .notRunning)
    }

    func testStatusItemOpensDashboardPanel() {
        let app = launchApp()
        _ = openDashboard(in: app)

        XCTAssertTrue(element(in: app, identifier: "netto.menubar.settings").exists)
        XCTAssertTrue(element(in: app, identifier: "netto.menubar.quit").exists)
        XCTAssertFalse(
            element(in: app, identifier: "netto.menubar.open-main").exists,
            "Menu-bar-only build should not expose an open-main entry"
        )
        XCTAssertTrue(element(in: app, identifier: "netto.dashboard.filter").exists)
    }

    func testStatusItemCanClosePanel() {
        let app = launchApp()
        _ = openMenuBarPanel(in: app)
        let statusItem = app.statusItems.matching(identifier: "netto.menu-bar").firstMatch
        statusItem.click()
        XCTAssertFalse(element(in: app, identifier: "netto.menubar.firewall").waitForExistence(timeout: 2))
    }
}