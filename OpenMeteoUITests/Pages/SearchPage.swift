//
//  SearchPage.swift
//  OpenMeteoUITests
//
//  Created by Kamil Misiag on 19/10/2026.
//

import XCTest

@MainActor
struct SearchPage {
    let app: XCUIApplication

    var title: XCUIElement { app.navigationBars["Where to?"] }
    var emptyStateTitle: XCUIElement { app.staticTexts["Find a city"] }
    var searchingLabel: XCUIElement { app.staticTexts["Searching…"] }
    var resultsHeader: XCUIElement { app.staticTexts["Results"] }
    var recentsHeader: XCUIElement { app.staticTexts["Recent"] }
    private var field: XCUIElement { app.searchFields.firstMatch }

    static func launch() -> SearchPage {
        let app = XCUIApplication()
        app.launchArguments += ["--sample-data", "-AppleLanguages", "(en)"]
        app.launch()
        return SearchPage(app: app).waitUntilShown()
    }

    func city(named name: String) -> XCUIElement {
        app.buttons.labelled(containing: name)
    }

    func type(_ text: String) -> SearchPage {
        field.waitUntilExists().tap()
        field.typeText(text)
        return self
    }

    func clearQuery() -> SearchPage {
        field.tap()
        field.buttons["Clear text"].waitUntilExists().tap()
        return self
    }

    func openCity(named name: String) -> RankingPage {
        city(named: name).waitUntilExists().tap()
        return RankingPage(app: app, city: name).waitUntilShown()
    }

    @discardableResult
    func waitUntilShown() -> SearchPage {
        field.waitUntilExists()
        return self
    }
}
