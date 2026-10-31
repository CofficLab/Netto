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

    /// 打开设置窗口并返回它。
    @discardableResult
    private func openSettingsWindow(in app: XCUIApplication) -> XCUIElement {
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

    /// 菜单栏「设置…」入口能打开设置窗口。
    func testSettingsMenuEntryOpensTheSettingsWindow() {
        let app = launchApp()
        _ = openDashboard(in: app)

        let settingsButton = app.buttons.matching(NSPredicate(format: "label == %@", "设置")).firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10), "设置按钮缺失")
        settingsButton.click()

        let settingsMenu = element(in: app, identifier: "netto.settings.menu")
        XCTAssertTrue(settingsMenu.waitForExistence(timeout: 10), "设置弹出层未打开")

        let openSettingsAction = element(in: app, identifier: "netto.settings.open")
        XCTAssertTrue(openSettingsAction.waitForExistence(timeout: 5), "「设置…」入口缺失")
        openSettingsAction.click()

        let window = openSettingsWindow(in: app)
        XCTAssertTrue(window.exists, "点击「设置…」后设置窗口未出现")
    }

    /// 设置窗口展示双栏结构与四个入口。
    func testSettingsWindowShowsSidebarEntries() {
        let app = launchApp()
        _ = openDashboard(in: app)

        let settingsButton = app.buttons.matching(NSPredicate(format: "label == %@", "设置")).firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10))
        settingsButton.click()
        XCTAssertTrue(element(in: app, identifier: "netto.settings.menu").waitForExistence(timeout: 10))

        element(in: app, identifier: "netto.settings.open").click()
        let window = openSettingsWindow(in: app)

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

        let settingsButton = app.buttons.matching(NSPredicate(format: "label == %@", "设置")).firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10))
        settingsButton.click()
        XCTAssertTrue(element(in: app, identifier: "netto.settings.menu").waitForExistence(timeout: 10))

        element(in: app, identifier: "netto.settings.open").click()
        let window = openSettingsWindow(in: app)

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

        let settingsButton = app.buttons.matching(NSPredicate(format: "label == %@", "设置")).firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10))
        settingsButton.click()
        XCTAssertTrue(element(in: app, identifier: "netto.settings.menu").waitForExistence(timeout: 10))

        element(in: app, identifier: "netto.settings.open").click()
        openSettingsWindow(in: app)

        // 「数据库」入口的详情曾带 `.navigationTitle("防火墙事件")`。
        let databaseEntry = sidebarEntry("数据库", in: app)
        XCTAssertTrue(databaseEntry.waitForExistence(timeout: 5))
        databaseEntry.click()

        let title = app.windows.firstMatch.title
        XCTAssertTrue(
            title.contains(settingsWindowTitle),
            "切换入口后窗口标题被改写为「\(title)」"
        )
    }

    // MARK: - 重复触发

    /// 重复触发「设置…」不会创建第二个设置窗口（只前置）。
    ///
    /// 第二次触发用 `⌘,`（应用菜单命令）：设置窗口打开后菜单栏 popover 会
    /// 关闭，「设置」按钮不再在可交互层级里，而 `⌘,` 始终可用 —— 正好覆盖
    /// 「窗口已存在时只前置、不新建」这条语义。
    func testOpeningSettingsTwiceDoesNotDuplicateTheWindow() {
        let app = launchApp()
        _ = openDashboard(in: app)

        let settingsButton = app.buttons.matching(NSPredicate(format: "label == %@", "设置")).firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10))
        settingsButton.click()
        XCTAssertTrue(element(in: app, identifier: "netto.settings.menu").waitForExistence(timeout: 10))

        element(in: app, identifier: "netto.settings.open").click()
        XCTAssertTrue(openSettingsWindow(in: app).waitForExistence(timeout: 20))

        // 再次触发（⌘,）：窗口已存在，只应前置。
        app.typeKey(",", modifierFlags: .command)
        XCTAssertTrue(openSettingsWindow(in: app).waitForExistence(timeout: 20))

        let settingsWindows = app.windows.matching(
            NSPredicate(format: "title == %@", settingsWindowTitle)
        )
        XCTAssertEqual(settingsWindows.count, 1, "重复触发创建了多个设置窗口")
    }
}
