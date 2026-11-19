import XCTest

/// 菜单栏仪表盘：筛选切换、防火墙引导与状态、应用详情与事件筛选。
final class NettoDashboardUITests: NettoUITestBase {
    func testDashboardShowsFirewallControlAndAppFilter() {
        let app = launchApp()
        _ = openDashboard(in: app)

        XCTAssertTrue(
            element(in: app, identifier: "netto.menubar.firewall.start").exists
                || element(in: app, identifier: "netto.menubar.firewall.stop").exists
        )
        XCTAssertTrue(element(in: app, identifier: "netto.filter.all").exists)
        XCTAssertTrue(element(in: app, identifier: "netto.apps.list").exists)
    }

    func testAllFilterChoicesAreAvailable() {
        let app = launchApp()
        _ = openDashboard(in: app)

        for identifier in ["netto.filter.all", "netto.filter.allowed", "netto.filter.rejected"] {
            XCTAssertTrue(element(in: app, identifier: identifier).waitForExistence(timeout: 5), "Missing filter: \(identifier)")
        }
    }

    func testAllowedAndRejectedFiltersCanBeSelected() {
        let app = launchApp()
        _ = openDashboard(in: app)

        for identifier in ["netto.filter.allowed", "netto.filter.rejected", "netto.filter.all"] {
            let option = element(in: app, identifier: identifier)
            XCTAssertTrue(option.waitForExistence(timeout: 5), "Missing filter: \(identifier)")
            option.click()
            XCTAssertTrue(element(in: app, identifier: "netto.apps.list").exists, "Selecting \(identifier) closed the dashboard")
        }
    }

    func testFirewallGuideShowsARecoveryPathWhenFirewallIsNotReady() {
        let app = launchApp()
        _ = openDashboard(in: app)

        let guide = element(in: app, identifier: "netto.firewall.guide")
        if guide.waitForExistence(timeout: 5) {
            // 引导视图应包含说明或恢复动作（开始/开启/允许/安装/前往系统设置等）。
            let actions = ["开始", "开启", "允许", "安装", "系统设置", "重启", "升级"]
            let found = actions.contains { element(in: app, containing: $0).exists }
            XCTAssertTrue(found, "Firewall guide is visible without an explanation or recovery action")
        } else {
            XCTAssertTrue(
                element(in: app, identifier: "netto.menubar.firewall.stop").exists
                    || element(in: app, containing: "防火墙状态").exists,
                "A running firewall should show its stop control or status when the guide is hidden"
            )
        }
    }

    func testFirewallStatusIsExposedToAccessibility() {
        let app = launchApp()
        _ = openDashboard(in: app)

        // 弹窗头部暴露防火墙启停按钮（运行中为停止，否则为开启）。
        let start = element(in: app, identifier: "netto.menubar.firewall.start")
        let stop = element(in: app, identifier: "netto.menubar.firewall.stop")
        XCTAssertTrue(
            start.waitForExistence(timeout: 10) || stop.exists,
            "菜单栏弹窗未暴露防火墙开关状态"
        )

        XCTAssertTrue(
            element(in: app, containing: "防火墙").waitForExistence(timeout: 10),
            "菜单栏弹窗未暴露防火墙状态文案"
        )
    }

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

        XCTAssertTrue(element(in: app, identifier: "netto.apps.list").exists)
    }

    func testAppDetailShowsEventFiltersAndExportAction() throws {
        let app = launchApp()
        _ = openDashboard(in: app)
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "netto.app.row."))
            .firstMatch
        guard row.waitForExistence(timeout: 10) else {
            throw XCTSkip("No app rows are visible in the current dashboard state")
        }

        row.click()
        let detail = element(in: app, identifier: "netto.app.detail")
        XCTAssertTrue(detail.waitForExistence(timeout: 8), "Clicking an app row did not open its detail")
        XCTAssertTrue(element(in: app, identifier: "netto.events.detail").exists)
        XCTAssertTrue(element(in: app, identifier: "netto.events.status-filter").exists)
        XCTAssertTrue(element(in: app, identifier: "netto.events.direction-filter").exists)
        XCTAssertTrue(element(in: app, identifier: "netto.events.export").exists)

        element(in: app, identifier: "netto.app.detail.back").click()
        XCTAssertTrue(element(in: app, identifier: "netto.apps.list").waitForExistence(timeout: 5))
    }

    func testEventStatusAndDirectionFiltersCanBeChanged() throws {
        let app = launchApp()
        _ = openDashboard(in: app)
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "netto.app.row."))
            .firstMatch
        guard row.waitForExistence(timeout: 10) else {
            throw XCTSkip("No app rows are visible in the current dashboard state")
        }

        row.click()
        let detail = element(in: app, identifier: "netto.app.detail")
        guard detail.waitForExistence(timeout: 8) else {
            throw XCTSkip("App detail is unavailable in this environment")
        }

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