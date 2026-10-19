//
//  ActivityDetailPage.swift
//  OpenMeteoUITests
//
//  Created by Kamil Misiag on 19/10/2026.
//

import XCTest

@MainActor
struct ActivityDetailPage {
    let app: XCUIApplication
    let activity: String
    let ranking: RankingPage

    var chartHeader: XCUIElement { app.staticTexts["Daily score"] }
    private var navigationBar: XCUIElement { app.navigationBars[activity] }

    func back() -> RankingPage {
        navigationBar.buttons["BackButton"].tap()
        return ranking.waitUntilShown()
    }

    @discardableResult
    func waitUntilShown() -> ActivityDetailPage {
        navigationBar.waitUntilExists()
        return self
    }
}
