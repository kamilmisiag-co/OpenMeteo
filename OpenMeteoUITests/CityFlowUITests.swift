//
//  CityFlowUITests.swift
//  OpenMeteoUITests
//
//  Created by Kamil Misiag on 19/10/2026.
//

import XCTest

final class CityFlowUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testSearchRankingDetailAndRecents() {
        let ranking = SearchPage.launch().type("Lisbon").openCity(named: "Lisbon")
        ranking.openHowScores().close()

        let detail = ranking.openActivity(named: "Surfing")
        detail.chartHeader.waitUntilExists()

        let search = detail.back().back().clearQuery()
        search.recentsHeader.waitUntilExists()
        XCTAssertTrue(search.city(named: "Lisbon").exists)
    }
}
