import XCTest

/// UI coverage for Netto's primary menu-bar workflow.
///
/// Tests only inspect or change local presentation state. They intentionally do
/// not install/enable the system extension, change firewall rules, or purchase
/// Store products because those actions affect the host machine/account.
class NettoUITestBase: XCTestCase {
    @MainActor private var launchedApp: XCUIApplication?

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    var app: XCUIApplication {
        if let launchedApp { return launchedApp }

        let newApp = XCUIApplication()
        newApp.launch()
        launchedApp = newApp
        return newApp
    }

    @MainActor
    func element(identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @MainActor
    @discardableResult
    func openDashboard() -> XCUIElement {
        let statusItem = app.statusItems.matching(identifier: "netto.menu-bar").firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 20), "Menu-bar status item was not installed")
        statusItem.click()

        let dashboard = element(identifier: "netto.dashboard")
        XCTAssertTrue(dashboard.waitForExistence(timeout: 20), "Dashboard popover did not appear")
        return dashboard
    }
}

final class NettoLaunchUITests: NettoUITestBase {
    @MainActor
    func testLaunchInstallsMenuBarStatusItem() {
        let statusItem = app.statusItems.matching(identifier: "netto.menu-bar").firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 20))
        XCTAssertNotEqual(app.state, .notRunning)
    }

    @MainActor
    func testStatusItemOpensDashboardPopover() {
        XCTAssertTrue(openDashboard().exists)
        XCTAssertTrue(element(identifier: "netto.dashboard.toolbar").exists)
        XCTAssertTrue(element(identifier: "netto.apps.list").exists)
    }

    @MainActor
    func testStatusItemCanCloseDashboardPopover() {
        _ = openDashboard()
        let statusItem = app.statusItems.matching(identifier: "netto.menu-bar").firstMatch
        statusItem.click()
        XCTAssertFalse(element(identifier: "netto.dashboard").waitForExistence(timeout: 2))
    }
}

final class NettoDashboardUITests: NettoUITestBase {
    @MainActor
    func testDashboardShowsFirewallControlAndAppFilter() {
        _ = openDashboard()

        let start = element(identifier: "netto.firewall.start")
        let stop = element(identifier: "netto.firewall.stop")
        XCTAssertTrue(
            start.waitForExistence(timeout: 10) || stop.waitForExistence(timeout: 10),
            "Dashboard does not expose a firewall start/stop control"
        )
        XCTAssertTrue(element(identifier: "netto.dashboard.filter").exists)
    }

    @MainActor
    func testAllFilterChoicesAreAvailable() {
        _ = openDashboard()

        for identifier in ["netto.filter.all", "netto.filter.allowed", "netto.filter.rejected"] {
            XCTAssertTrue(element(identifier: identifier).waitForExistence(timeout: 5), "Missing filter: \(identifier)")
        }
    }

    @MainActor
    func testAllowedAndRejectedFiltersCanBeSelected() {
        _ = openDashboard()

        for identifier in ["netto.filter.allowed", "netto.filter.rejected", "netto.filter.all"] {
            let option = element(identifier: identifier)
            XCTAssertTrue(option.waitForExistence(timeout: 5), "Missing filter: \(identifier)")
            option.click()
            XCTAssertTrue(element(identifier: "netto.dashboard").exists, "Selecting \(identifier) closed the dashboard")
        }
    }

    @MainActor
    func testFirewallGuideShowsARecoveryPathWhenFirewallIsNotReady() {
        _ = openDashboard()

        let guide = element(identifier: "netto.firewall.guide")
        if guide.waitForExistence(timeout: 5) {
            let install = element(identifier: "netto.extension.install")
            let openSettings = element(identifier: "netto.extension.system-settings")
            let guideText = element(containing: "系统扩展")
            XCTAssertTrue(
                install.exists || openSettings.exists || guideText.exists,
                "Firewall guide is visible without an explanation or recovery action"
            )
        } else {
            XCTAssertTrue(
                element(identifier: "netto.firewall.stop").exists,
                "A running firewall should show its stop control when the guide is hidden"
            )
        }
    }

    @MainActor
    func testFirewallStatusIsExposedToAccessibility() {
        _ = openDashboard()
        let status = element(containing: "防火墙")
        XCTAssertTrue(status.waitForExistence(timeout: 10), "Status item does not expose a firewall status label")
    }

    @MainActor
    func testDashboardRemainsUsableAfterRepeatedFilterChanges() {
        _ = openDashboard()
        let choices = ["netto.filter.allowed", "netto.filter.rejected", "netto.filter.all"]

        for _ in 0..<2 {
            for identifier in choices {
                let option = element(identifier: identifier)
                XCTAssertTrue(option.waitForExistence(timeout: 5))
                option.click()
            }
        }

        XCTAssertTrue(element(identifier: "netto.dashboard.toolbar").exists)
        XCTAssertTrue(element(identifier: "netto.apps.list").exists)
    }

    @MainActor
    func testAppDetailShowsEventFiltersAndExportAction() throws {
        _ = openDashboard()
        let rows = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "netto.app.row."))
        let row = rows.firstMatch
        guard row.waitForExistence(timeout: 10) else {
            throw XCTSkip("No app rows are visible in the current dashboard state")
        }

        row.hover()

        XCTAssertTrue(element(identifier: "netto.app.detail").waitForExistence(timeout: 10))
        XCTAssertTrue(element(identifier: "netto.events.detail").exists)
        XCTAssertTrue(element(identifier: "netto.events.status-filter").exists)
        XCTAssertTrue(element(identifier: "netto.events.direction-filter").exists)
        XCTAssertTrue(element(identifier: "netto.events.export").exists)
    }

    @MainActor
    func testEventStatusAndDirectionFiltersCanBeChanged() throws {
        _ = openDashboard()
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "netto.app.row."))
            .firstMatch
        guard row.waitForExistence(timeout: 10) else {
            throw XCTSkip("No app rows are visible in the current dashboard state")
        }

        row.hover()
        XCTAssertTrue(element(identifier: "netto.app.detail").waitForExistence(timeout: 10))

        for identifier in [
            "netto.events.status.允许",
            "netto.events.status.阻止",
            "netto.events.status.全部",
            "netto.events.direction.入",
            "netto.events.direction.出",
            "netto.events.direction.全部",
        ] {
            let option = element(identifier: identifier)
            XCTAssertTrue(option.waitForExistence(timeout: 5), "Missing event filter: \(identifier)")
            option.click()
            XCTAssertTrue(element(identifier: "netto.events.detail").exists)
        }
    }
}

final class NettoSettingsUITests: NettoUITestBase {
    @MainActor
    func testSettingsMenuOpensAndContainsActions() {
        _ = openDashboard()

        let settingsButton = element(identifier: "netto.settings.button")
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings menu button is missing")
        settingsButton.click()

        let settingsMenu = element(identifier: "netto.settings.menu")
        XCTAssertTrue(settingsMenu.waitForExistence(timeout: 5), "Settings actions popover did not open")
        XCTAssertGreaterThan(settingsMenu.buttons.count, 0, "Settings popover contains no actionable entries")
    }

    @MainActor
    func testSettingsMenuCanBeOpenedAndClosedRepeatedly() {
        _ = openDashboard()
        let settingsButton = element(identifier: "netto.settings.button")
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))

        for _ in 0..<2 {
            settingsButton.click()
            XCTAssertTrue(element(identifier: "netto.settings.menu").waitForExistence(timeout: 5))
            settingsButton.click()
            XCTAssertFalse(element(identifier: "netto.settings.menu").waitForExistence(timeout: 2))
        }
    }

    @MainActor
    func testSettingsMenuExposesGuideAboutAndQuitActions() {
        _ = openDashboard()
        element(identifier: "netto.settings.button").click()
        XCTAssertTrue(element(identifier: "netto.settings.menu").waitForExistence(timeout: 5))

        for label in ["使用引导", "关于", "退出"] {
            XCTAssertTrue(
                app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch.exists,
                "Settings menu is missing the \(label) action"
            )
        }
    }
}

private extension NettoUITestBase {
    @MainActor
    func element(containing text: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text))
            .firstMatch
    }
}
