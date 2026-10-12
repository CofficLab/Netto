import XCTest

/// 设置菜单：弹出层、使用引导窗口、关于面板、退出动作。
final class NettoSettingsUITests: NettoUITestBase {
    /// 设置按钮：dashboard 工具栏中的「设置」按钮（id 在不同构建中不稳定，按 label 匹配）。
    func settingsButton(in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@", "设置")).firstMatch
    }

    func testSettingsMenuOpensAndContainsActions() {
        let app = launchApp()
        _ = openDashboard(in: app)

        let settingsButton = settingsButton(in: app)
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings menu button is missing")
        settingsButton.click()

        let settingsMenu = element(in: app, identifier: "netto.settings.menu")
        XCTAssertTrue(settingsMenu.waitForExistence(timeout: 5), "Settings actions popover did not open")
        XCTAssertGreaterThan(settingsMenu.buttons.count, 0, "Settings popover contains no actionable entries")
    }

    func testSettingsMenuCanBeOpenedAndClosedRepeatedly() {
        let app = launchApp()
        _ = openDashboard(in: app)
        let settingsButton = settingsButton(in: app)
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))

        for _ in 0..<2 {
            settingsButton.click()
            XCTAssertTrue(element(in: app, identifier: "netto.settings.menu").waitForExistence(timeout: 5))
            settingsButton.click()
            XCTAssertFalse(element(in: app, identifier: "netto.settings.menu").waitForExistence(timeout: 2))
        }
    }

    func testSettingsMenuExposesGuideAboutAndQuitActions() {
        let app = launchApp()
        _ = openDashboard(in: app)
        settingsButton(in: app).click()
        XCTAssertTrue(element(in: app, identifier: "netto.settings.menu").waitForExistence(timeout: 5))

        for label in ["使用引导", "关于", "退出"] {
            XCTAssertTrue(
                app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch.exists,
                "Settings menu is missing the \(label) action"
            )
        }
    }

    func testGuideActionOpensWelcomeWindow() {
        let app = launchApp()
        _ = openDashboard(in: app)
        settingsButton(in: app).click()
        XCTAssertTrue(element(in: app, identifier: "netto.settings.menu").waitForExistence(timeout: 5))

        let guideAction = element(in: app, identifier: "netto.settings.guide")
        XCTAssertTrue(guideAction.waitForExistence(timeout: 5), "Guide action is missing")
        guideAction.click()

        let welcomeWindow = app.windows.matching(
            NSPredicate(format: "title CONTAINS %@", "Welcome to TravelMode")
        ).firstMatch
        XCTAssertTrue(welcomeWindow.waitForExistence(timeout: 10), "Guide action did not open the welcome window")

        // 欢迎引导应包含可推进的内容（按钮/文本），不强依赖具体按钮 label。
        XCTAssertTrue(
            welcomeWindow.buttons.count > 0 || welcomeWindow.staticTexts.count > 0,
            "Welcome guide window appears empty"
        )
    }

    func testAboutActionOpensTheSystemAboutPanel() {
        let app = launchApp()
        _ = openDashboard(in: app)
        settingsButton(in: app).click()
        XCTAssertTrue(element(in: app, identifier: "netto.settings.menu").waitForExistence(timeout: 5))

        let aboutAction = element(in: app, identifier: "netto.settings.about")
        XCTAssertTrue(aboutAction.waitForExistence(timeout: 5), "About action is missing")
        aboutAction.click()

        let aboutPanel = app.windows.matching(
            NSPredicate(format: "title CONTAINS %@", "TravelMode")
        ).firstMatch
        XCTAssertTrue(aboutPanel.waitForExistence(timeout: 10), "About action did not open the system About panel")
    }

    func testQuitActionTerminatesTheApp() {
        let app = launchApp()
        _ = openDashboard(in: app)
        settingsButton(in: app).click()
        XCTAssertTrue(element(in: app, identifier: "netto.settings.menu").waitForExistence(timeout: 5))

        let quitAction = element(in: app, identifier: "netto.settings.quit")
        XCTAssertTrue(quitAction.waitForExistence(timeout: 5), "Quit action is missing")
        quitAction.click()

        XCTAssertTrue(app.wait(for: .notRunning, timeout: 10), "Quit action did not terminate the app")
    }
}
