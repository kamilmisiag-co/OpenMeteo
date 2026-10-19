//
//  HowScoresPage.swift
//  OpenMeteoUITests
//
//  Created by Kamil Misiag on 19/10/2026.
//

import XCTest

@MainActor
struct HowScoresPage {
    let app: XCUIApplication

    private var navigationBar: XCUIElement { app.navigationBars["How scores work"] }

    func close() {
        navigationBar.buttons["Done"].tap()
        navigationBar.waitUntilGone()
    }

    @discardableResult
    func waitUntilShown() -> HowScoresPage {
        navigationBar.waitUntilExists()
        return self
    }
}
