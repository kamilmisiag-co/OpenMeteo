//
//  SearchUITests.swift
//  OpenMeteoUITests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import XCTest

final class SearchUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsSearchScreenWithFirstLaunchState() {
        let search = SearchPage.launch()

        search.title.waitUntilExists()
        search.emptyStateTitle.waitUntilExists()
    }

    @MainActor
    func testSingleCharacterKeepsFirstLaunchState() {
        let search = SearchPage.launch().type("L")

        search.emptyStateTitle.waitUntilExists()
        XCTAssertFalse(search.resultsHeader.waitForExistence(timeout: 2))
        XCTAssertFalse(search.searchingLabel.exists)
    }
}
