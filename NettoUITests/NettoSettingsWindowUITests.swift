import XCTest

/// 设置窗口 UI 覆盖：入口可达性、双栏结构、入口切换与窗口标题保持。
///
/// 这些测试只观察本机界面状态，不改动防火墙规则、不安装系统扩展、
/// 不购买商店商品。
final class NettoSettingsWindowUITests: NettoUITestBase {
    /// 设置窗口标题。
    private let settingsWindowTitle = "设置"

    /// 设置窗口（按标题匹配）。
    private func settingsWindow(in app: XCUIApplication) -> XCUIElement {
        app.windows.matching(NSPredicate(format: "title == %@", settingsWindowTitle)).firstMatch
    }

    /// 通过主窗口工具栏的「设置」按钮打开设置窗口并返回它。
    @discardableResult
    private func openSettingsWindow(in app: XCUIApplication) -> XCUIElement {
        let button = element(in: app, identifier: "netto.toolbar.settings")
        XCTAssertTrue(button.waitForExistence(timeout: 10), "主窗口工具栏缺少「设置」按钮")
        button.click()
        return waitForSettingsWindow(in: app)
    }

    /// 等待设置窗口出现（不触发打开）。
    @discardableResult
    private func waitForSettingsWindow(in app: XCUIApplication) -> XCUIElement {
        let window = settingsWindow(in: app)
        XCTAssertTrue(window.waitForExistence(timeout: 20), "设置窗口未打开")
        return window
    }

    /// 侧边栏入口按钮（外观 / 通用 / 商店 / 数据库）。
    private func sidebarEntry(_ title: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@", title)).firstMatch
    }

    /// 详情区静态文本（SwiftUI 的 `Text` 以 `value` 暴露文本，`label` 可能为空）。
    private func detailText(_ contains: String, in app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", contains, contains)
        ).firstMatch
    }

    // MARK: - 入口可达性

    /// 主窗口工具栏「设置」按钮能打开设置窗口。
    func testToolbarSettingsButtonOpensTheSettingsWindow() {
        let app = launchApp()
        _ = openDashboard(in: app)

        let settingsButton = element(in: app, identifier: "netto.toolbar.settings")
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10), "「设置」按钮缺失")
        settingsButton.click()

        let window = waitForSettingsWindow(in: app)
        XCTAssertTrue(window.exists, "点击「设置」后设置窗口未出现")
    }

    /// 设置窗口展示双栏结构与四个入口。
    func testSettingsWindowShowsSidebarEntries() {
        let app = launchApp()
        _ = openDashboard(in: app)

        openSettingsWindow(in: app)

        for entry in ["外观", "通用", "商店", "数据库"] {
            XCTAssertTrue(
                sidebarEntry(entry, in: app).waitForExistence(timeout: 5),
                "设置窗口缺少入口「\(entry)」"
            )
        }
    }

    // MARK: - 入口切换

    /// 点击侧边栏入口后，右侧详情区切换到对应内容。
    func testSelectingSidebarEntrySwitchesDetailPane() {
        let app = launchApp()
        _ = openDashboard(in: app)

        openSettingsWindow(in: app)

        // 切到「通用」：详情区应出现「数据目录」（通用入口的独有内容）。
        let generalEntry = sidebarEntry("通用", in: app)
        XCTAssertTrue(generalEntry.waitForExistence(timeout: 5))
        generalEntry.click()

        let dataFolder = detailText("数据目录", in: app)
        XCTAssertTrue(
            dataFolder.waitForExistence(timeout: 10),
            "点击「通用」后右侧详情未切换到通用页"
        )
    }

    /// 切换入口不应改写宿主窗口标题（详情视图的 navigationTitle 会被
    /// SwiftUI 提升为窗口标题，需要宿主守卫保持「设置」）。
    func testSwitchingEntryKeepsWindowTitle() {
        let app = launchApp()
        _ = openDashboard(in: app)

        openSettingsWindow(in: app)

        // 「数据库」入口的详情曾带 `.navigationTitle("防火墙事件")`。
        let databaseEntry = sidebarEntry("数据库", in: app)
        XCTAssertTrue(databaseEntry.waitForExistence(timeout: 5))
        databaseEntry.click()

        // 主窗口也在前台，不能直接读 `app.windows.firstMatch`；按标题断言
        // 设置窗口仍然存在（标题被改写时会变成 0 个匹配）。
        XCTAssertTrue(
            settingsWindow(in: app).waitForExistence(timeout: 5),
            "切换入口后设置窗口标题被改写"
        )
    }

    // MARK: - 商店入口

    /// 「商店」入口展示与兄弟项目同构的设置页（订阅信息 / 应用内购买 / 恢复购买）。
    func testStoreEntryShowsStoreSettingsPage() {
        let app = launchApp()
        _ = openDashboard(in: app)

        openSettingsWindow(in: app)

        let storeEntry = sidebarEntry("商店", in: app)
        XCTAssertTrue(storeEntry.waitForExistence(timeout: 5), "设置窗口缺少入口「商店」")
        storeEntry.click()

        for section in ["订阅信息", "应用内购买", "恢复购买"] {
            XCTAssertTrue(
                detailText(section, in: app).waitForExistence(timeout: 10),
                "商店页缺少「\(section)」分组"
            )
        }
    }

    // MARK: - 重复触发

    /// 重复触发不会创建第二个设置窗口（只前置）。
    ///
    /// 第二次触发用 `⌘,`（应用菜单命令）：设置窗口打开后会成为前台，
    /// `⌘,` 始终可用 —— 正好覆盖「窗口已存在时只前置、不新建」这条语义。
    func testOpeningSettingsTwiceDoesNotDuplicateTheWindow() {
        let app = launchApp()
        _ = openDashboard(in: app)

        openSettingsWindow(in: app)

        // 再次触发（⌘,）：窗口已存在，只应前置。
        app.typeKey(",", modifierFlags: .command)
        XCTAssertTrue(waitForSettingsWindow(in: app).waitForExistence(timeout: 20))

        let settingsWindows = app.windows.matching(
            NSPredicate(format: "title == %@", settingsWindowTitle)
        )
        XCTAssertEqual(settingsWindows.count, 1, "重复触发创建了多个设置窗口")
    }
}
