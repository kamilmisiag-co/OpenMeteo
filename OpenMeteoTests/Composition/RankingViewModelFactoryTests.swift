//
//  RankingViewModelFactoryTests.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import Testing
@testable import OpenMeteo

@Suite("Ranking view model factory")
@MainActor
struct RankingViewModelFactoryTests {
    @Test("Makes a new view model for the given city with the injected dependencies")
    func makesViewModel() async {
        let loader = ScriptedForecastLoader(steps: [])
        let presenter = RecordingRankingPresenter()
        let factory = RankingViewModelFactory(dependencies: ViewModelFixtures.rankingDependencies(loader: loader, presenter: presenter))

        let lisbon = factory.makeRankingViewModel(for: Fixtures.lisbon)
        let bergen = factory.makeRankingViewModel(for: Fixtures.bergen)
        await bergen.load()

        #expect(lisbon !== bergen)
        #expect(lisbon.city == Fixtures.lisbon)
        #expect(bergen.city == Fixtures.bergen)
        #expect(presenter.placeholderCities == [Fixtures.lisbon, Fixtures.bergen])
        #expect(loader.requestedCities == [Fixtures.bergen])
    }
}
