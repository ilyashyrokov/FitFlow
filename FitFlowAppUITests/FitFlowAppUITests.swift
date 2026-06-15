import XCTest

final class FitFlowAppUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testTabNavigationExposesReadableDestinations() {
        let app = XCUIApplication(bundleIdentifier: "com.fitflow.app")
        app.launch()

        let todayTab = app.buttons["tab.today"]
        let historyTab = app.buttons["tab.history"]
        let progressTab = app.buttons["tab.progress"]

        XCTAssertTrue(todayTab.waitForExistence(timeout: 5))
        XCTAssertTrue(historyTab.isHittable)
        XCTAssertTrue(progressTab.isHittable)

        progressTab.tap()
        XCTAssertTrue(app.staticTexts["Прогресс"].waitForExistence(timeout: 2))

        historyTab.tap()
        XCTAssertTrue(app.staticTexts["История"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testTabBarRemainsUsableAtAccessibilityTextSize() {
        let app = XCUIApplication(bundleIdentifier: "com.fitflow.app")
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ]
        app.launch()

        for identifier in ["tab.today", "tab.history", "tab.progress"] {
            let tab = app.buttons[identifier]
            XCTAssertTrue(tab.waitForExistence(timeout: 5))
            XCTAssertTrue(tab.isHittable)
        }

        app.buttons["tab.progress"].tap()
        XCTAssertTrue(app.staticTexts["Прогресс"].waitForExistence(timeout: 2))
    }
}
