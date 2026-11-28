import XCTest

/// 设置入口：菜单栏弹窗的「设置…」行、⌘, 命令、窗口去重与应用菜单退出。
final class NetpauseSettingsUITests: NetpauseUITestBase {
    private let settingsWindowTitle = "设置"

    /// 设置窗口（按标题匹配）。
    private func settingsWindow(in app: XCUIApplication) -> XCUIElement {
        app.windows.matching(NSPredicate(format: "title == %@", settingsWindowTitle)).firstMatch
    }

    func testMenuBarPanelExposesSettingsEntry() {
        let app = launchApp()
        _ = openMenuBarPanel(in: app)

        XCTAssertTrue(
            element(in: app, identifier: "netpause.menubar.settings").waitForExistence(timeout: 10),
            "菜单栏弹窗缺少「设置…」入口"
        )
    }

    func testSettingsWindowOpensFromMenuBarEntry() {
        let app = launchApp()
        _ = openMenuBarPanel(in: app)

        element(in: app, identifier: "netpause.menubar.settings").click()

        XCTAssertTrue(
            settingsWindow(in: app).waitForExistence(timeout: 20),
            "点击「设置…」后设置窗口未出现"
        )
    }

    /// 开发语言为英语时，未匹配到中文变体的环境回落到英文窗口标题。
    func testSettingsWindowUsesEnglishFallback() {
        let app = launchApp(language: "en")

        XCTAssertTrue(
            app.windows.matching(NSPredicate(format: "title == %@", "Settings"))
                .firstMatch.waitForExistence(timeout: 20),
            "英文环境下设置窗口标题未回落到 Settings"
        )
    }

    /// 重复触发（菜单栏入口 + ⌘,）不会创建第二个设置窗口。
    func testRepeatedSettingsRequestsDoNotDuplicateWindow() {
        let app = launchApp()
        _ = openMenuBarPanel(in: app)
        element(in: app, identifier: "netpause.menubar.settings").click()
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

        app.typeKey("q", modifierFlags: .command)

        XCTAssertTrue(app.wait(for: .notRunning, timeout: 10), "⌘Q 未结束应用")
    }
}