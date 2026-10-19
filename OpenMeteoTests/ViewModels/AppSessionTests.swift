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
        openMeteo: AppStandard.openMeteoURL,
        licence: AppStandard.licenceURL,
        geoNames: AppStandard.geoNamesURL
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
        let recents = ScriptedRecentCitiesManager(cities: [PreviewCities.bergen], afterVisit: [PreviewCities.lisbon, PreviewCities.bergen])
        let session = makeSession(recents: recents)

        session.open(PreviewCities.lisbon)

        #expect(session.navigator.path == [.ranking(PreviewCities.lisbon)])
        #expect(recents.calls == [.recentCities, .recordVisit(PreviewCities.lisbon)])
        #expect(session.search.recents == [PreviewCities.lisbon, PreviewCities.bergen])
    }

    @Test("Opening the city that is already shown pushes nothing and records no second visit")
    func repeatedOpenIgnored() {
        let recents = ScriptedRecentCitiesManager(afterVisit: [PreviewCities.lisbon])
        let session = makeSession(recents: recents)

        session.open(PreviewCities.lisbon)
        session.open(PreviewCities.lisbon)

        #expect(session.navigator.path == [.ranking(PreviewCities.lisbon)])
        #expect(recents.calls == [.recentCities, .recordVisit(PreviewCities.lisbon)])
    }
}
