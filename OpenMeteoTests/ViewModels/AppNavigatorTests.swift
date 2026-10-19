//
//  AppNavigatorTests.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import Testing
@testable import OpenMeteo

@Suite("App navigator")
@MainActor
struct AppNavigatorTests {
    private func makeNavigator() -> (AppNavigator, CountingRankingViewModelFactory) {
        let factory = CountingRankingViewModelFactory()
        return (AppNavigator(rankings: factory), factory)
    }

    @Test("Showing two rankings pushes both routes")
    func pushesRoutes() {
        let (navigator, _) = makeNavigator()

        navigator.showRanking(for: Fixtures.lisbon)
        navigator.showRanking(for: Fixtures.bergen)

        #expect(navigator.path == [.ranking(Fixtures.lisbon), .ranking(Fixtures.bergen)])
    }

    @Test("Showing the route that is already on top pushes nothing")
    func ignoresRepeatedPush() {
        let (navigator, _) = makeNavigator()

        #expect(navigator.showRanking(for: Fixtures.lisbon))
        #expect(!navigator.showRanking(for: Fixtures.lisbon))
        #expect(navigator.showRanking(for: Fixtures.bergen))

        #expect(navigator.path == [.ranking(Fixtures.lisbon), .ranking(Fixtures.bergen)])
    }

    @Test("A city's view model is made once while the city is shown")
    func sharedViewModel() {
        let (navigator, factory) = makeNavigator()
        navigator.showRanking(for: Fixtures.lisbon)

        let first = navigator.rankingViewModel(for: Fixtures.lisbon)
        let second = navigator.rankingViewModel(for: Fixtures.lisbon)

        #expect(first === second)
        #expect(factory.madeCities == [Fixtures.lisbon])
    }

    @Test("Each city gets its own view model")
    func viewModelPerCity() {
        let (navigator, factory) = makeNavigator()
        navigator.path = [.ranking(Fixtures.lisbon), .ranking(Fixtures.bergen)]

        let lisbon = navigator.rankingViewModel(for: Fixtures.lisbon)
        let bergen = navigator.rankingViewModel(for: Fixtures.bergen)

        #expect(lisbon !== bergen)
        #expect(lisbon.city == Fixtures.lisbon)
        #expect(bergen.city == Fixtures.bergen)
        #expect(factory.madeCities == [Fixtures.lisbon, Fixtures.bergen])
    }

    @Test("Leaving a city releases its view model so reopening it starts fresh")
    func popCityReleasesViewModel() {
        let (navigator, factory) = makeNavigator()
        navigator.path = [.ranking(Fixtures.lisbon)]
        let before = navigator.rankingViewModel(for: Fixtures.lisbon)

        navigator.path = []
        navigator.showRanking(for: Fixtures.lisbon)

        #expect(navigator.rankingViewModel(for: Fixtures.lisbon) !== before)
        #expect(factory.madeCities == [Fixtures.lisbon, Fixtures.lisbon])
    }

    @Test("Leaving one city keeps the view models of cities still on the path")
    func pruneKeepsRemainingCities() {
        let (navigator, factory) = makeNavigator()
        navigator.path = [.ranking(Fixtures.lisbon), .ranking(Fixtures.bergen)]
        let lisbon = navigator.rankingViewModel(for: Fixtures.lisbon)
        _ = navigator.rankingViewModel(for: Fixtures.bergen)

        navigator.path.removeLast()

        #expect(navigator.rankingViewModel(for: Fixtures.lisbon) === lisbon)
        #expect(factory.madeCities.count == 2)
    }

    @Test("Asking for a view model does not notify observers")
    func lookupIsUnobserved() {
        let (navigator, _) = makeNavigator()
        navigator.path = [.ranking(Fixtures.lisbon), .ranking(Fixtures.bergen)]
        let probe = ObservationProbe()

        probe.track {
            _ = navigator.path
            _ = navigator.rankingViewModel(for: Fixtures.lisbon)
        }
        _ = navigator.rankingViewModel(for: Fixtures.bergen)
        _ = navigator.rankingViewModel(for: Fixtures.lisbon)

        #expect(probe.changeCount == 0)
        navigator.showRanking(for: Fixtures.lisbon)
        #expect(probe.changeCount == 1)
    }
}
