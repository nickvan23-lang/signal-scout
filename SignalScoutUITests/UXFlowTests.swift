import XCTest
final class SignalScoutReleaseUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }
    private func capture(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
    func testGuideMapAndReturn() {
        let app = XCUIApplication(); app.launchArguments = ["-SignalScoutScreenshotMode", "-SignalScoutLiveFixture"]; app.launch()
        XCTAssertTrue(app.staticTexts["Find your signal"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["Pause scanning"].isHittable)
        capture(app, "01-refined-scanner")
        app.buttons["How to search"].tap()
        XCTAssertTrue(app.staticTexts["A signal is a clue, not a location."].waitForExistence(timeout: 5))
        capture(app, "02-search-guide")
        app.buttons["Done"].tap()
        app.buttons["Live Map"].tap()
        app.buttons["Open full screen signal map"].tap()
        XCTAssertTrue(app.buttons["Close full screen map"].waitForExistence(timeout: 5))
        app.buttons["Zoom in"].tap(); app.buttons["Fit all"].tap()
        capture(app, "03-readable-map")
        app.buttons["Close full screen map"].tap()
        app.buttons["Device List"].tap()
        XCTAssertTrue(app.staticTexts["Studio headphones"].exists)
        capture(app, "04-signal-list")
    }
    func testTrackingPauseResumeAndReturn() {
        let app = XCUIApplication(); app.launchArguments = ["-SignalScoutScreenshotMode", "-SignalScoutLiveFixture", "-SignalScoutTrackingScreenshotMode"]; app.launch()
        XCTAssertTrue(app.buttons["Stop tracking"].waitForExistence(timeout: 15))
        capture(app, "05-refined-tracking")
        app.buttons["Pause scanning"].tap()
        XCTAssertTrue(app.staticTexts["Scanning paused"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Reset comparison"].isEnabled)
        capture(app, "06-paused-last-reading")
        app.buttons["Resume scanning"].tap()
        XCTAssertTrue(app.buttons["Pause scanning"].exists)
        XCTAssertTrue(app.buttons["Reset comparison"].isEnabled)
        app.buttons["Stop tracking"].tap()
        XCTAssertTrue(app.staticTexts["Find your signal"].waitForExistence(timeout: 5))
    }
    func testLargeTextKeepsTrackingControlsReachable() {
        let app = XCUIApplication(); app.launchArguments = ["-SignalScoutScreenshotMode", "-SignalScoutLiveFixture", "-SignalScoutTrackingScreenshotMode", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]; app.launch()
        XCTAssertTrue(app.buttons["Stop tracking"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Reset comparison"].isHittable)
        XCTAssertTrue(app.buttons["Pause scanning"].isHittable)
        capture(app, "07-accessibility-text-tracking")
    }
}
