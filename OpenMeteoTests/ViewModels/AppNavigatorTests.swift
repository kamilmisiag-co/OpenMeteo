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

    @Test("Showing the route that is already on top pushes nothing")
    func ignoresRepeatedPush() {
        let (navigator, _) = makeNavigator()

        #expect(navigator.showRanking(for: PreviewCities.lisbon))
        #expect(!navigator.showRanking(for: PreviewCities.lisbon))
        #expect(navigator.showDetail(of: .surfing, in: PreviewCities.lisbon))
        #expect(!navigator.showDetail(of: .surfing, in: PreviewCities.lisbon))
        #expect(navigator.showDetail(of: .skiing, in: PreviewCities.lisbon))

        #expect(navigator.path == [.ranking(PreviewCities.lisbon), .detail(PreviewCities.lisbon, .surfing), .detail(PreviewCities.lisbon, .skiing)])
    }

    @Test("The ranking and detail of one city share a view model")
    func sharedViewModel() {
        let (navigator, factory) = makeNavigator()
        navigator.showRanking(for: PreviewCities.lisbon)
        let ranking = navigator.rankingViewModel(for: PreviewCities.lisbon)

        navigator.showDetail(of: .surfing, in: PreviewCities.lisbon)
        let detail = navigator.rankingViewModel(for: PreviewCities.lisbon)

        #expect(ranking === detail)
        #expect(factory.madeCities == [PreviewCities.lisbon])
    }

    @Test("Each city gets its own view model")
    func viewModelPerCity() {
        let (navigator, factory) = makeNavigator()
        navigator.path = [.ranking(PreviewCities.lisbon), .ranking(PreviewCities.bergen)]

        let lisbon = navigator.rankingViewModel(for: PreviewCities.lisbon)
        let bergen = navigator.rankingViewModel(for: PreviewCities.bergen)

        #expect(lisbon !== bergen)
        #expect(lisbon.city == PreviewCities.lisbon)
        #expect(bergen.city == PreviewCities.bergen)
        #expect(factory.madeCities == [PreviewCities.lisbon, PreviewCities.bergen])
    }

    @Test("Popping only the detail keeps the city's view model")
    func popDetailKeepsViewModel() {
        let (navigator, factory) = makeNavigator()
        navigator.path = [.ranking(PreviewCities.lisbon), .detail(PreviewCities.lisbon, .surfing)]
        let before = navigator.rankingViewModel(for: PreviewCities.lisbon)

        navigator.path.removeLast()

        #expect(navigator.rankingViewModel(for: PreviewCities.lisbon) === before)
        #expect(factory.madeCities.count == 1)
    }

    @Test("Leaving a city releases its view model so reopening it starts fresh")
    func popCityReleasesViewModel() {
        let (navigator, factory) = makeNavigator()
        navigator.path = [.ranking(PreviewCities.lisbon), .detail(PreviewCities.lisbon, .surfing)]
        let before = navigator.rankingViewModel(for: PreviewCities.lisbon)

        navigator.path = []
        navigator.showRanking(for: PreviewCities.lisbon)

        #expect(navigator.rankingViewModel(for: PreviewCities.lisbon) !== before)
        #expect(factory.madeCities == [PreviewCities.lisbon, PreviewCities.lisbon])
    }

    @Test("Leaving one city keeps the view models of cities still on the path")
    func pruneKeepsRemainingCities() {
        let (navigator, factory) = makeNavigator()
        navigator.path = [.ranking(PreviewCities.lisbon), .ranking(PreviewCities.bergen)]
        let lisbon = navigator.rankingViewModel(for: PreviewCities.lisbon)
        _ = navigator.rankingViewModel(for: PreviewCities.bergen)

        navigator.path.removeLast()

        #expect(navigator.rankingViewModel(for: PreviewCities.lisbon) === lisbon)
        #expect(factory.madeCities.count == 2)
    }

    @Test("Asking for a view model does not notify observers")
    func lookupIsUnobserved() {
        let (navigator, _) = makeNavigator()
        navigator.path = [.ranking(PreviewCities.lisbon), .ranking(PreviewCities.bergen)]
        let probe = ObservationProbe()

        probe.track {
            _ = navigator.path
            _ = navigator.rankingViewModel(for: PreviewCities.lisbon)
        }
        _ = navigator.rankingViewModel(for: PreviewCities.bergen)
        _ = navigator.rankingViewModel(for: PreviewCities.lisbon)

        #expect(probe.changeCount == 0)
        navigator.showDetail(of: .skiing, in: PreviewCities.bergen)
        #expect(probe.changeCount == 1)
    }
}
