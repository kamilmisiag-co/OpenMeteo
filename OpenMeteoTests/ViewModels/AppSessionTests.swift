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
            navigator: AppNavigator(rankings: CountingRankingViewModelFactory()),
            links: Self.links,
            dayCount: 5
        )
    }

    @Test("Opening a city shows its ranking and records the visit")
    func openRecordsAndNavigates() {
        let recents = ScriptedRecentCitiesManager(cities: [Fixtures.bergen], afterVisit: [Fixtures.lisbon, Fixtures.bergen])
        let session = makeSession(recents: recents)

        session.open(Fixtures.lisbon)

        #expect(session.navigator.path == [.ranking(Fixtures.lisbon)])
        #expect(recents.calls == [.recentCities, .recordVisit(Fixtures.lisbon)])
        #expect(session.search.recents == [Fixtures.lisbon, Fixtures.bergen])
    }

    @Test("Opening the city that is already shown pushes nothing and records no second visit")
    func repeatedOpenIgnored() {
        let recents = ScriptedRecentCitiesManager(afterVisit: [Fixtures.lisbon])
        let session = makeSession(recents: recents)

        session.open(Fixtures.lisbon)
        session.open(Fixtures.lisbon)

        #expect(session.navigator.path == [.ranking(Fixtures.lisbon)])
        #expect(recents.calls == [.recentCities, .recordVisit(Fixtures.lisbon)])
    }

    @Test("The session hands its search, navigator, links and day count to the screens")
    func passesConfiguration() {
        let search = SearchViewModel(dependencies: ViewModelFixtures.searchDependencies())
        let navigator = AppNavigator(rankings: CountingRankingViewModelFactory())

        let session = AppSession(search: search, navigator: navigator, links: Self.links, dayCount: 5)

        #expect(session.search === search)
        #expect(session.navigator === navigator)
        #expect(session.links == Self.links)
        #expect(session.dayCount == 5)
        #expect(navigator.path.isEmpty)
    }
}
