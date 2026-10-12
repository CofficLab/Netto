import XCTest

/// 启动与状态栏：App 启动安装菜单栏条目、点击展开/收起仪表盘。
final class NettoLaunchUITests: NettoUITestBase {
    func testLaunchInstallsMenuBarStatusItem() {
        let app = launchApp()
        let statusItem = app.statusItems.matching(identifier: "netto.menu-bar").firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 20))
        XCTAssertNotEqual(app.state, .notRunning)
    }

    func testStatusItemOpensDashboardPopover() {
        let app = launchApp()
        XCTAssertTrue(openDashboard(in: app).exists)
        XCTAssertTrue(element(in: app, identifier: "netto.dashboard.toolbar").exists)
        XCTAssertTrue(element(in: app, identifier: "netto.apps.list").exists)
    }

    func testStatusItemCanCloseDashboardPopover() {
        let app = launchApp()
        _ = openDashboard(in: app)
        let statusItem = app.statusItems.matching(identifier: "netto.menu-bar").firstMatch
        statusItem.click()
        XCTAssertFalse(element(in: app, identifier: "netto.dashboard").waitForExistence(timeout: 2))
    }
}
