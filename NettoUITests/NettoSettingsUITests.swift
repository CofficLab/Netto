import XCTest

/// 工具栏「设置」按钮：共享工具栏中的齿轮入口、打开设置窗口、
/// 重复触发不新建窗口、应用菜单退出命令。
final class NettoSettingsUITests: NettoUITestBase {
    private let settingsWindowTitle = "设置"

    /// 主窗口共享工具栏的「设置」按钮。
    private func settingsButton(in app: XCUIApplication) -> XCUIElement {
        element(in: app, identifier: "netto.toolbar.settings")
    }

    /// 设置窗口（按标题匹配）。
    private func settingsWindow(in app: XCUIApplication) -> XCUIElement {
        app.windows.matching(NSPredicate(format: "title == %@", settingsWindowTitle)).firstMatch
    }

    func testToolbarExposesSettingsButton() {
        let app = launchApp()
        _ = openDashboard(in: app)

        XCTAssertTrue(
            settingsButton(in: app).waitForExistence(timeout: 10),
            "主窗口工具栏缺少「设置」按钮"
        )
    }

    func testSettingsButtonOpensSettingsWindow() {
        let app = launchApp()
        _ = openDashboard(in: app)

        let button = settingsButton(in: app)
        XCTAssertTrue(button.waitForExistence(timeout: 10), "「设置」按钮缺失")
        button.click()

        XCTAssertTrue(
            settingsWindow(in: app).waitForExistence(timeout: 20),
            "点击「设置」后设置窗口未出现"
        )
    }

    /// 重复触发（工具栏按钮 + ⌘,）不会创建第二个设置窗口。
    func testRepeatedSettingsRequestsDoNotDuplicateWindow() {
        let app = launchApp()
        _ = openDashboard(in: app)

        let button = settingsButton(in: app)
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        button.click()
        XCTAssertTrue(settingsWindow(in: app).waitForExistence(timeout: 20))

        app.typeKey(",", modifierFlags: .command)
        XCTAssertTrue(settingsWindow(in: app).waitForExistence(timeout: 20))

        XCTAssertEqual(
            app.windows.matching(NSPredicate(format: "title == %@", settingsWindowTitle)).count,
            1,
            "重复触发创建了多个设置窗口"
        )
    }

    func testQuitCommandTerminatesTheApp() {
        let app = launchApp()
        _ = openDashboard(in: app)

        app.typeKey("q", modifierFlags: .command)

        XCTAssertTrue(app.wait(for: .notRunning, timeout: 10), "⌘Q 未结束应用")
    }
}
