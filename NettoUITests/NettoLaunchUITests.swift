import XCTest

/// 启动与状态栏：主窗口启动即打开、菜单栏条目安装、面板展开/收起。
final class NettoLaunchUITests: NettoUITestBase {
    func testLaunchOpensMainWindowDashboard() {
        let app = launchApp()
        _ = openDashboard(in: app)
        XCTAssertTrue(element(in: app, identifier: "netto.toolbar.settings").waitForExistence(timeout: 10))
        XCTAssertTrue(element(in: app, identifier: "netto.apps.list").waitForExistence(timeout: 10))
    }

    func testLaunchInstallsMenuBarStatusItem() {
        let app = launchApp()
        let statusItem = app.statusItems.matching(identifier: "netto.menu-bar").firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 20))
        XCTAssertNotEqual(app.state, .notRunning)
    }

    func testStatusItemOpensCompactPanel() {
        let app = launchApp()
        _ = openMenuBarPanel(in: app)

        for identifier in [
            "netto.menubar.open-main",
            "netto.menubar.settings",
            "netto.menubar.quit",
        ] {
            XCTAssertTrue(
                element(in: app, identifier: identifier).exists,
                "Menu-bar panel is missing \(identifier)"
            )
        }
    }

    func testStatusItemCanClosePanel() {
        let app = launchApp()
        _ = openMenuBarPanel(in: app)
        let statusItem = app.statusItems.matching(identifier: "netto.menu-bar").firstMatch
        statusItem.click()
        XCTAssertFalse(element(in: app, identifier: "netto.menubar.firewall").waitForExistence(timeout: 2))
    }
}
