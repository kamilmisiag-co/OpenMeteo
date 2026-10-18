//
//  CitySearchStateTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Testing

@Suite("City search state")
struct CitySearchStateTests {
    @Test("Only results and no-results show their query", arguments: [
        (CitySearchState.idle, String?.none),
        (CitySearchState.searching(query: "Lisbon", previous: [Fixtures.lisbon]), String?.none),
        (CitySearchState.results(query: "Lisbon", cities: [Fixtures.lisbon, Fixtures.lisboa]), "Lisbon"),
        (CitySearchState.noResults(query: "Atlantis"), "Atlantis"),
        (CitySearchState.failed(query: "Bergen", failure: .offline), String?.none),
        (CitySearchState.failed(query: "Bergen", failure: .unavailable), String?.none),
    ])
    func shownQuery(state: CitySearchState, expected: String?) {
        #expect(state.shownQuery == expected)
    }

    @Test("Results show their cities and a search in progress keeps showing the previous ones", arguments: [
        (CitySearchState.idle, [City]()),
        (CitySearchState.searching(query: "Lisbon", previous: [Fixtures.bergen]), [Fixtures.bergen]),
        (CitySearchState.searching(query: "Lisbon", previous: []), []),
        (CitySearchState.results(query: "Lisbon", cities: [Fixtures.lisbon, Fixtures.lisboa]), [Fixtures.lisbon, Fixtures.lisboa]),
        (CitySearchState.noResults(query: "Atlantis"), []),
        (CitySearchState.failed(query: "Bergen", failure: .offline), []),
        (CitySearchState.failed(query: "Bergen", failure: .unavailable), []),
    ])
    func shownCities(state: CitySearchState, expected: [City]) {
        #expect(state.shownCities == expected)
    }
}
