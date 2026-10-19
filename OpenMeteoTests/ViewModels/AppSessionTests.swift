//
//  AppSessionTests.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Testing
@testable import OpenMeteo

@Suite("App session")
@MainActor
struct AppSessionTests {
    private static let links = AttributionLinks(
        openMeteo: URL(string: "https://open-meteo.com"),
        licence: nil,
        geoNames: URL(string: "https://www.geonames.org")
    )

    private func makeSession(recents: ScriptedRecentCitiesManager) -> AppSession {
        AppSession(
            search: SearchViewModel(dependencies: ViewModelFixtures.searchDependencies(recents: recents)),
            links: Self.links,
            dayCount: 5
        )
    }

    @Test("Opening a city records the visit")
    func openRecords() {
        let recents = ScriptedRecentCitiesManager(cities: [Fixtures.bergen], afterVisit: [Fixtures.lisbon, Fixtures.bergen])
        let session = makeSession(recents: recents)

        session.open(Fixtures.lisbon)

        #expect(recents.calls == [.recentCities, .recordVisit(Fixtures.lisbon)])
        #expect(session.search.recents == [Fixtures.lisbon, Fixtures.bergen])
    }

    @Test("The session hands its search, links and day count to the screens")
    func passesConfiguration() {
        let search = SearchViewModel(dependencies: ViewModelFixtures.searchDependencies())

        let session = AppSession(search: search, links: Self.links, dayCount: 5)

        #expect(session.search === search)
        #expect(session.links == Self.links)
        #expect(session.dayCount == 5)
    }
}
