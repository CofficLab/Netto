import XCTest

/// UI coverage for Netto's primary menu-bar workflow.
///
/// Tests only inspect or change local presentation state. They intentionally do
/// not install/enable the system extension, change firewall rules, or purchase
/// Store products because those actions affect the host machine/account.
class NettoUITestBase: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    @MainActor
    func element(in app: XCUIApplication, identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @MainActor
    @discardableResult
    func openDashboard(in app: XCUIApplication) -> XCUIElement {
        let statusItem = app.statusItems.matching(identifier: "netto.menu-bar").firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 20), "Menu-bar status item was not installed")
        statusItem.click()

        let dashboard = element(in: app, identifier: "netto.dashboard")
        XCTAssertTrue(dashboard.waitForExistence(timeout: 20), "Dashboard popover did not appear")
        return dashboard
    }
}

final class NettoLaunchUITests: NettoUITestBase {
    @MainActor
    func testLaunchInstallsMenuBarStatusItem() {
        let app = launchApp()
        let statusItem = app.statusItems.matching(identifier: "netto.menu-bar").firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 20))
        XCTAssertNotEqual(app.state, .notRunning)
    }

    @MainActor
    func testStatusItemOpensDashboardPopover() {
        let app = launchApp()
        XCTAssertTrue(openDashboard(in: app).exists)
        XCTAssertTrue(element(in: app, identifier: "netto.dashboard.toolbar").exists)
        XCTAssertTrue(element(in: app, identifier: "netto.apps.list").exists)
    }

    @MainActor
    func testStatusItemCanCloseDashboardPopover() {
        let app = launchApp()
        _ = openDashboard(in: app)
        let statusItem = app.statusItems.matching(identifier: "netto.menu-bar").firstMatch
        statusItem.click()
        XCTAssertFalse(element(in: app, identifier: "netto.dashboard").waitForExistence(timeout: 2))
    }
}

final class NettoDashboardUITests: NettoUITestBase {
    @MainActor
    func testDashboardShowsFirewallControlAndAppFilter() {
        let app = launchApp()
        _ = openDashboard(in: app)

        let start = element(in: app, identifier: "netto.firewall.start")
        let stop = element(in: app, identifier: "netto.firewall.stop")
        XCTAssertTrue(
            start.waitForExistence(timeout: 10) || stop.waitForExistence(timeout: 10),
            "Dashboard does not expose a firewall start/stop control"
        )
        XCTAssertTrue(element(in: app, identifier: "netto.dashboard.filter").exists)
    }

    @MainActor
    func testAllFilterChoicesAreAvailable() {
        let app = launchApp()
        _ = openDashboard(in: app)

        for identifier in ["netto.filter.all", "netto.filter.allowed", "netto.filter.rejected"] {
            XCTAssertTrue(element(in: app, identifier: identifier).waitForExistence(timeout: 5), "Missing filter: \(identifier)")
        }
    }

    @MainActor
    func testAllowedAndRejectedFiltersCanBeSelected() {
        let app = launchApp()
        _ = openDashboard(in: app)

        for identifier in ["netto.filter.allowed", "netto.filter.rejected", "netto.filter.all"] {
            let option = element(in: app, identifier: identifier)
            XCTAssertTrue(option.waitForExistence(timeout: 5), "Missing filter: \(identifier)")
            option.click()
            XCTAssertTrue(element(in: app, identifier: "netto.dashboard").exists, "Selecting \(identifier) closed the dashboard")
        }
    }

    @MainActor
    func testFirewallGuideShowsARecoveryPathWhenFirewallIsNotReady() {
        let app = launchApp()
        _ = openDashboard(in: app)

        let guide = element(in: app, identifier: "netto.firewall.guide")
        if guide.waitForExistence(timeout: 5) {
            let install = element(in: app, identifier: "netto.extension.install")
            let openSettings = element(in: app, identifier: "netto.extension.system-settings")
            let guideText = element(in: app, containing: "系统扩展")
            XCTAssertTrue(
                install.exists || openSettings.exists || guideText.exists,
                "Firewall guide is visible without an explanation or recovery action"
            )
        } else {
            XCTAssertTrue(
                element(in: app, identifier: "netto.firewall.stop").exists,
                "A running firewall should show its stop control when the guide is hidden"
            )
        }
    }

    @MainActor
    func testFirewallStatusIsExposedToAccessibility() {
        let app = launchApp()
        _ = openDashboard(in: app)
        let status = element(in: app, containing: "防火墙")
        XCTAssertTrue(status.waitForExistence(timeout: 10), "Status item does not expose a firewall status label")
    }

    @MainActor
    func testDashboardRemainsUsableAfterRepeatedFilterChanges() {
        let app = launchApp()
        _ = openDashboard(in: app)
        let choices = ["netto.filter.allowed", "netto.filter.rejected", "netto.filter.all"]

        for _ in 0..<2 {
            for identifier in choices {
                let option = element(in: app, identifier: identifier)
                XCTAssertTrue(option.waitForExistence(timeout: 5))
                option.click()
            }
        }

        XCTAssertTrue(element(in: app, identifier: "netto.dashboard.toolbar").exists)
        XCTAssertTrue(element(in: app, identifier: "netto.apps.list").exists)
    }

    @MainActor
    func testAppDetailShowsEventFiltersAndExportAction() throws {
        let app = launchApp()
        _ = openDashboard(in: app)
        let rows = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "netto.app.row."))
        let row = rows.firstMatch
        guard row.waitForExistence(timeout: 10) else {
            throw XCTSkip("No app rows are visible in the current dashboard state")
        }

        row.hover()

        XCTAssertTrue(element(in: app, identifier: "netto.app.detail").waitForExistence(timeout: 10))
        XCTAssertTrue(element(in: app, identifier: "netto.events.detail").exists)
        XCTAssertTrue(element(in: app, identifier: "netto.events.status-filter").exists)
        XCTAssertTrue(element(in: app, identifier: "netto.events.direction-filter").exists)
        XCTAssertTrue(element(in: app, identifier: "netto.events.export").exists)
    }

    @MainActor
    func testEventStatusAndDirectionFiltersCanBeChanged() throws {
        let app = launchApp()
        _ = openDashboard(in: app)
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "netto.app.row."))
            .firstMatch
        guard row.waitForExistence(timeout: 10) else {
            throw XCTSkip("No app rows are visible in the current dashboard state")
        }

        row.hover()
        XCTAssertTrue(element(in: app, identifier: "netto.app.detail").waitForExistence(timeout: 10))

        for identifier in [
            "netto.events.status.允许",
            "netto.events.status.阻止",
            "netto.events.status.全部",
            "netto.events.direction.入",
            "netto.events.direction.出",
            "netto.events.direction.全部",
        ] {
            let option = element(in: app, identifier: identifier)
            XCTAssertTrue(option.waitForExistence(timeout: 5), "Missing event filter: \(identifier)")
            option.click()
            XCTAssertTrue(element(in: app, identifier: "netto.events.detail").exists)
        }
    }
}

final class NettoSettingsUITests: NettoUITestBase {
    @MainActor
    func testSettingsMenuOpensAndContainsActions() {
        let app = launchApp()
        _ = openDashboard(in: app)

        let settingsButton = element(in: app, identifier: "netto.settings.button")
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings menu button is missing")
        settingsButton.click()

        let settingsMenu = element(in: app, identifier: "netto.settings.menu")
        XCTAssertTrue(settingsMenu.waitForExistence(timeout: 5), "Settings actions popover did not open")
        XCTAssertGreaterThan(settingsMenu.buttons.count, 0, "Settings popover contains no actionable entries")
    }

    @MainActor
    func testSettingsMenuCanBeOpenedAndClosedRepeatedly() {
        let app = launchApp()
        _ = openDashboard(in: app)
        let settingsButton = element(in: app, identifier: "netto.settings.button")
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))

        for _ in 0..<2 {
            settingsButton.click()
            XCTAssertTrue(element(in: app, identifier: "netto.settings.menu").waitForExistence(timeout: 5))
            settingsButton.click()
            XCTAssertFalse(element(in: app, identifier: "netto.settings.menu").waitForExistence(timeout: 2))
        }
    }

    @MainActor
    func testSettingsMenuExposesGuideAboutAndQuitActions() {
        let app = launchApp()
        _ = openDashboard(in: app)
        element(in: app, identifier: "netto.settings.button").click()
        XCTAssertTrue(element(in: app, identifier: "netto.settings.menu").waitForExistence(timeout: 5))

        for label in ["使用引导", "关于", "退出"] {
            XCTAssertTrue(
                app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch.exists,
                "Settings menu is missing the \(label) action"
            )
        }
    }

    @MainActor
    func testGuideActionOpensWelcomeWindow() {
        let app = launchApp()
        _ = openDashboard(in: app)
        element(in: app, identifier: "netto.settings.button").click()
        XCTAssertTrue(element(in: app, identifier: "netto.settings.menu").waitForExistence(timeout: 5))

        let guideAction = element(in: app, identifier: "netto.settings.guide")
        XCTAssertTrue(guideAction.waitForExistence(timeout: 5), "Guide action is missing")
        guideAction.click()

        let welcomeWindow = app.windows.matching(
            NSPredicate(format: "title CONTAINS %@", "Welcome to TravelMode")
        ).firstMatch
        XCTAssertTrue(welcomeWindow.waitForExistence(timeout: 10), "Guide action did not open the welcome window")

        let nextButton = welcomeWindow.buttons["下一步"]
        XCTAssertTrue(nextButton.exists, "Welcome guide has no next-step action")
        nextButton.click()
        XCTAssertTrue(
            welcomeWindow.staticTexts["网络过滤"].waitForExistence(timeout: 5),
            "Next did not advance the guide to its network filtering step"
        )
    }

    @MainActor
    func testAboutActionOpensTheSystemAboutPanel() {
        let app = launchApp()
        _ = openDashboard(in: app)
        element(in: app, identifier: "netto.settings.button").click()
        XCTAssertTrue(element(in: app, identifier: "netto.settings.menu").waitForExistence(timeout: 5))

        let aboutAction = element(in: app, identifier: "netto.settings.about")
        XCTAssertTrue(aboutAction.waitForExistence(timeout: 5), "About action is missing")
        aboutAction.click()

        let aboutPanel = app.windows.matching(
            NSPredicate(format: "title CONTAINS %@", "About TravelMode")
        ).firstMatch
        XCTAssertTrue(aboutPanel.waitForExistence(timeout: 10), "About action did not open the system About panel")
    }

    @MainActor
    func testQuitActionTerminatesTheApp() {
        let app = launchApp()
        _ = openDashboard(in: app)
        element(in: app, identifier: "netto.settings.button").click()
        XCTAssertTrue(element(in: app, identifier: "netto.settings.menu").waitForExistence(timeout: 5))

        let quitAction = element(in: app, identifier: "netto.settings.quit")
        XCTAssertTrue(quitAction.waitForExistence(timeout: 5), "Quit action is missing")
        quitAction.click()

        XCTAssertTrue(app.wait(for: .notRunning, timeout: 10), "Quit action did not terminate the app")
    }
}

private extension NettoUITestBase {
    @MainActor
    func element(in app: XCUIApplication, containing text: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text))
            .firstMatch
    }
}
