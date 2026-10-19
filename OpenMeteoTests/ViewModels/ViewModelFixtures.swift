//
//  ViewModelFixtures.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
@testable import OpenMeteo

@MainActor
enum ViewModelFixtures {
    static let debounce = Duration.milliseconds(250)
    static let progressDelay = Duration.milliseconds(300)
    static let standardDayCount = 6

    static func rankingDependencies(
        loader: ScriptedForecastLoader = ScriptedForecastLoader(steps: []),
        updater: ScriptedForecastStateUpdater = ScriptedForecastStateUpdater(),
        daySelector: ScriptedDaySelector = ScriptedDaySelector(),
        summarizer: ScriptedRankingSummarizer = ScriptedRankingSummarizer(summary: RankingSummary(ranking: [], selectedDay: nil, hasStrongTopPick: false)),
        insights: ScriptedInsightProvider = ScriptedInsightProvider(),
        freshness: ScriptedFreshnessEvaluator = ScriptedFreshnessEvaluator(freshness: .fresh),
        clock: ManualClock = ManualClock(now: Fixtures.referenceNow),
        presenter: RecordingRankingPresenter = RecordingRankingPresenter(),
        detailPresenter: RecordingDetailPresenter = RecordingDetailPresenter()
    ) -> RankingViewModel.Dependencies {
        RankingViewModel.Dependencies(
            loader: loader,
            updater: updater,
            daySelector: daySelector,
            summarizer: summarizer,
            insights: insights,
            freshness: freshness,
            dates: clock,
            presenter: presenter,
            detailPresenter: detailPresenter,
            standardDayCount: standardDayCount
        )
    }

    static func searchDependencies(
        resolver: SearchResolverDouble = SearchResolverDouble(immediate: { _, _ in nil }, resolution: { _ in nil }),
        recents: ScriptedRecentCitiesManager = ScriptedRecentCitiesManager(),
        sleeper: ControlledSleeper = ControlledSleeper()
    ) -> SearchViewModel.Dependencies {
        SearchViewModel.Dependencies(
            resolver: resolver,
            recents: recents,
            sleeper: sleeper,
            debounce: debounce,
            progressDelay: progressDelay
        )
    }
}
