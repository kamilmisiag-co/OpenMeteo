//
//  RankingPage.swift
//  OpenMeteoUITests
//
//  Created by Kamil Misiag on 19/10/2026.
//

import XCTest

@MainActor
struct RankingPage {
    let app: XCUIApplication
    let city: String

    private var navigationBar: XCUIElement { app.navigationBars[city] }

    func openActivity(named name: String) -> ActivityDetailPage {
        app.buttons.labelled(containing: name).waitUntilExists().tap()
        return ActivityDetailPage(app: app, activity: name, ranking: self).waitUntilShown()
    }

    func openHowScores() -> HowScoresPage {
        navigationBar.buttons["How scores work"].waitUntilExists().tap()
        return HowScoresPage(app: app).waitUntilShown()
    }

    func back() -> SearchPage {
        navigationBar.buttons["BackButton"].tap()
        return SearchPage(app: app).waitUntilShown()
    }

    @discardableResult
    func waitUntilShown() -> RankingPage {
        navigationBar.waitUntilExists()
        app.descendants(matching: .any).labelled(containing: "Loading forecast").waitUntilGone()
        return self
    }
}
