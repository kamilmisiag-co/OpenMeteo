//
//  SearchUITests.swift
//  OpenMeteoUITests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import XCTest

final class SearchUITests: XCTestCase {
    private let timeout: TimeInterval = 10

    @MainActor
    func testLaunchShowsSearchScreenWithFirstLaunchState() throws {
        let app = launchAppWithoutRecents()

        XCTAssertTrue(app.navigationBars["Where to?"].exists)
        XCTAssertTrue(app.staticTexts["Find a city"].waitForExistence(timeout: timeout))
    }

    @MainActor
    func testSingleCharacterKeepsFirstLaunchState() throws {
        let app = launchAppWithoutRecents()
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: timeout))

        field.tap()
        field.typeText("L")

        XCTAssertTrue(app.staticTexts["Find a city"].waitForExistence(timeout: timeout))
        XCTAssertFalse(app.staticTexts["Searching…"].exists)
        XCTAssertFalse(app.staticTexts["Results"].exists)
    }

    @MainActor
    private func launchAppWithoutRecents() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Where to?"].waitForExistence(timeout: timeout))
        clearRecents(in: app)
        return app
    }

    @MainActor
    private func clearRecents(in app: XCUIApplication) {
        let clear = app.buttons["Clear"]
        guard clear.exists else { return }
        clear.tap()
        let confirm = app.buttons["Clear Recents"]
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        confirm.tap()
    }
}
