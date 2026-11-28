import XCTest

/// 菜单栏仪表盘：筛选切换、防火墙引导与状态、应用详情与事件筛选。
final class NetpauseDashboardUITests: NetpauseUITestBase {
    func testDashboardShowsFirewallControlAndAppFilter() throws {
        let app = launchApp()
        _ = try openDashboard(in: app)

        XCTAssertTrue(
            element(in: app, identifier: "netpause.menubar.firewall.start").exists
                || element(in: app, identifier: "netpause.menubar.firewall.stop").exists
        )
        XCTAssertTrue(element(in: app, identifier: "netpause.filter.all").exists)
        XCTAssertTrue(element(in: app, identifier: "netpause.apps.list").exists)
    }

    func testAllFilterChoicesAreAvailable() throws {
        let app = launchApp()
        _ = try openDashboard(in: app)

        for identifier in ["netpause.filter.all", "netpause.filter.allowed", "netpause.filter.rejected"] {
            XCTAssertTrue(element(in: app, identifier: identifier).waitForExistence(timeout: 5), "Missing filter: \(identifier)")
        }
    }

    func testAllowedAndRejectedFiltersCanBeSelected() throws {
        let app = launchApp()
        _ = try openDashboard(in: app)

        for identifier in ["netpause.filter.allowed", "netpause.filter.rejected", "netpause.filter.all"] {
            let option = element(in: app, identifier: identifier)
            XCTAssertTrue(option.waitForExistence(timeout: 5), "Missing filter: \(identifier)")
            option.click()
            XCTAssertTrue(element(in: app, identifier: "netpause.apps.list").exists, "Selecting \(identifier) closed the dashboard")
        }
    }

    func testFirewallGuideShowsARecoveryPathWhenFirewallIsNotReady() {
        let app = launchApp()
        _ = openMenuBarPanel(in: app)

        let guide = element(in: app, identifier: "netpause.firewall.guide")
        if guide.waitForExistence(timeout: 5) {
            // 引导视图应包含说明或恢复动作（开始/开启/允许/安装/前往系统设置等）。
            let actions = ["开始", "开启", "允许", "安装", "系统设置", "重启", "升级"]
            let found = actions.contains { element(in: app, containing: $0).exists }
            XCTAssertTrue(found, "Firewall guide is visible without an explanation or recovery action")
        } else {
            XCTAssertTrue(
                element(in: app, identifier: "netpause.menubar.firewall.stop").exists
                    || element(in: app, containing: "防火墙状态").exists,
                "A running firewall should show its stop control or status when the guide is hidden"
            )
        }
    }

    func testFirewallStatusIsExposedToAccessibility() {
        let app = launchApp()
        _ = openMenuBarPanel(in: app)

        // 弹窗头部暴露防火墙启停按钮（运行中为停止，否则为开启）。
        let start = element(in: app, identifier: "netpause.menubar.firewall.start")
        let stop = element(in: app, identifier: "netpause.menubar.firewall.stop")
        XCTAssertTrue(
            start.waitForExistence(timeout: 10) || stop.exists,
            "菜单栏弹窗未暴露防火墙开关状态"
        )

        XCTAssertTrue(
            element(in: app, containing: "防火墙").waitForExistence(timeout: 10)
                || element(in: app, identifier: "netpause.firewall.guide").exists,
            "菜单栏弹窗未暴露防火墙状态文案"
        )
    }

    func testDashboardRemainsUsableAfterRepeatedFilterChanges() throws {
        let app = launchApp()
        _ = try openDashboard(in: app)
        let choices = ["netpause.filter.allowed", "netpause.filter.rejected", "netpause.filter.all"]

        for _ in 0..<2 {
            for identifier in choices {
                let option = element(in: app, identifier: identifier)
                XCTAssertTrue(option.waitForExistence(timeout: 5))
                option.click()
            }
        }

        XCTAssertTrue(element(in: app, identifier: "netpause.apps.list").exists)
    }

    func testAppRowDoesNotOpenEventLog() throws {
        let app = launchApp()
        _ = try openDashboard(in: app)
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "netpause.app.row."))
            .firstMatch
        guard row.waitForExistence(timeout: 10) else {
            throw XCTSkip("No app rows are visible in the current dashboard state")
        }

        row.click()
        // 应用联网日志已从弹窗移除：点击行不应离开应用列表。
        XCTAssertTrue(element(in: app, identifier: "netpause.apps.list").waitForExistence(timeout: 3))
        XCTAssertFalse(element(in: app, identifier: "netpause.app.detail").exists)
        XCTAssertFalse(element(in: app, identifier: "netpause.events.detail").exists)
    }
}