//
//  RankingViewModelTests.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Testing
@testable import OpenMeteo

@Suite("Ranking view model")
@MainActor
struct RankingViewModelTests {
    nonisolated enum Fetch: CaseIterable, Sendable {
        case load
        case retry
        case refresh

        @MainActor
        func run(on viewModel: RankingViewModel) async {
            switch self {
            case .load: await viewModel.load()
            case .retry: await viewModel.retry()
            case .refresh: await viewModel.refresh()
            }
        }
    }

    private struct Harness {
        let viewModel: RankingViewModel
        let loader: ScriptedForecastLoader
        let updater: ScriptedForecastStateUpdater
        let daySelector: ScriptedDaySelector
        let summarizer: ScriptedRankingSummarizer
        let freshness: ScriptedFreshnessEvaluator
        let clock: ManualClock
        let presenter: RecordingRankingPresenter
    }

    nonisolated private static let forecast = Fixtures.lisbonForecast()
    nonisolated private static let result = Fixtures.result(forecast)
    nonisolated private static let outcome = ForecastLoadOutcome.loaded(result)
    nonisolated private static let loaded = shown(onDay: nil)
    nonisolated private static let freshness = Freshness.stale(since: Fixtures.referenceNow.addingTimeInterval(-3_600))
    nonisolated private static let summary = RankingSummary(
        ranking: [RankedActivity(rank: 1, outlook: Fixtures.lisbonOutlooks[2], score: 76)],
        selectedDay: 5,
        hasStrongTopPick: true
    )

    nonisolated private static func shown(onDay day: Int?) -> ForecastState {
        .loaded(LoadedForecast(result: result, selectedDay: day))
    }

    private func makeHarness(
        steps: [ScriptedForecastLoader.Step] = [.init(outcome)],
        states: [ForecastState] = [loaded],
        selections: [Int?] = []
    ) -> Harness {
        let loader = ScriptedForecastLoader(steps: steps)
        let updater = ScriptedForecastStateUpdater(states: states)
        let daySelector = ScriptedDaySelector(selections: selections)
        let summarizer = ScriptedRankingSummarizer(summary: Self.summary)
        let freshness = ScriptedFreshnessEvaluator(freshness: Self.freshness)
        let clock = ManualClock(now: Fixtures.referenceNow)
        let presenter = RecordingRankingPresenter()
        let dependencies = ViewModelFixtures.rankingDependencies(
            loader: loader,
            updater: updater,
            daySelector: daySelector,
            summarizer: summarizer,
            freshness: freshness,
            clock: clock,
            presenter: presenter
        )
        return Harness(
            viewModel: RankingViewModel(city: Fixtures.lisbon, dependencies: dependencies),
            loader: loader,
            updater: updater,
            daySelector: daySelector,
            summarizer: summarizer,
            freshness: freshness,
            clock: clock,
            presenter: presenter
        )
    }

    private func loadedHarness(
        states: [ForecastState] = [loaded],
        selections: [Int?] = []
    ) async -> Harness {
        let harness = makeHarness(states: states, selections: selections)
        await harness.viewModel.load()
        return harness
    }

    private func presentationRequest(now: Date = Fixtures.referenceNow) -> RecordingRankingPresenter.Request {
        RecordingRankingPresenter.Request(summary: Self.summary, forecast: Self.forecast, freshness: Self.freshness, now: now)
    }

    @Test("Starts loading with the presenter's placeholder and asks no collaborator for a forecast")
    func initialState() {
        let harness = makeHarness()

        #expect(harness.viewModel.state == .loading)
        #expect(harness.viewModel.isLoading)
        #expect(harness.viewModel.now == Fixtures.referenceNow)
        #expect(harness.viewModel.placeholder == RecordingRankingPresenter.labelledPlaceholder(for: Fixtures.lisbon))
        #expect(harness.viewModel.presentation == nil)
        #expect(harness.viewModel.failure == nil)
        #expect(harness.presenter.placeholderCities == [Fixtures.lisbon])
        #expect(harness.loader.requestedCities.isEmpty)
        #expect(harness.summarizer.calls.isEmpty)
        #expect(harness.presenter.requests.isEmpty)
    }

    @Test("A load asks the loader for the city, reads the clock and shows what the updater makes of the outcome")
    func load() async {
        let cached = ForecastState.loaded(LoadedForecast(result: Fixtures.result(Self.forecast, origin: .cache), selectedDay: 2))
        let harness = makeHarness(states: [cached])
        harness.clock.advance(by: 90)

        await harness.viewModel.load()

        #expect(harness.loader.requestedCities == [Fixtures.lisbon])
        #expect(harness.updater.calls == [.init(current: .loading, outcome: Self.outcome, city: Fixtures.lisbon)])
        #expect(harness.viewModel.state == cached)
        #expect(!harness.viewModel.isLoading)
        #expect(harness.viewModel.failure == nil)
        #expect(harness.viewModel.now == Fixtures.referenceNow.addingTimeInterval(90))
    }

    @Test("The presentation is the presenter's view of the summary and freshness of the shown forecast", arguments: [nil, 3] as [Int?])
    func presentationOfShownForecast(selectedDay: Int?) async {
        let harness = await loadedHarness(states: [Self.shown(onDay: selectedDay)])

        let presentation = harness.viewModel.presentation

        #expect(presentation == RecordingRankingPresenter.labelledPresentation(for: presentationRequest()))
        #expect(harness.presenter.requests == [presentationRequest()])
        #expect(harness.summarizer.calls == [.init(forecast: Self.forecast, day: selectedDay)])
        #expect(harness.freshness.calls == [.init(result: Self.result, now: Fixtures.referenceNow)])
    }

    @Test("A failed state exposes its failure with nothing to present", arguments: [ServiceFailure.offline, .noUpcomingDays, .unavailable])
    func failure(_ failure: ServiceFailure) async {
        let harness = await loadedHarness(states: [.failed(failure)])

        #expect(harness.viewModel.failure == failure)
        #expect(!harness.viewModel.isLoading)
        #expect(harness.viewModel.presentation == nil)
        #expect(harness.summarizer.calls.isEmpty)
    }

    @Test("A load once the state has settled fetches nothing", arguments: [RankingViewModelTests.loaded, .failed(.offline)])
    func loadOnlyWhileLoading(settled: ForecastState) async {
        let harness = await loadedHarness(states: [settled])

        await harness.viewModel.load()

        #expect(harness.loader.requestedCities.count == 1)
        #expect(harness.updater.calls.count == 1)
        #expect(harness.viewModel.state == settled)
    }

    @Test("A fetch asked for while another one runs fetches nothing", arguments: Fetch.allCases)
    func overlappingFetch(_ second: Fetch) async {
        let gate = AsyncGate()
        let harness = makeHarness(steps: [.init(Self.outcome, after: gate), .init(Self.outcome)])

        let first = Task { await harness.viewModel.load() }
        #expect(await Polling.until { harness.loader.requestedCities.count == 1 })
        await second.run(on: harness.viewModel)
        #expect(harness.viewModel.state == .loading)
        await gate.open()
        await first.value

        #expect(harness.loader.requestedCities.count == 1)
        #expect(harness.updater.calls.count == 1)
        #expect(harness.viewModel.state == Self.loaded)
    }

    @Test("Try again shows loading while it fetches and then shows the updated state")
    func retry() async {
        let gate = AsyncGate()
        let harness = makeHarness(
            steps: [.init(.failed(.offline)), .init(Self.outcome, after: gate)],
            states: [.failed(.offline), Self.loaded]
        )
        await harness.viewModel.load()

        let retry = Task { await harness.viewModel.retry() }
        #expect(await Polling.until { harness.loader.requestedCities.count == 2 })
        #expect(harness.viewModel.isLoading)
        #expect(harness.viewModel.failure == nil)
        await gate.open()
        await retry.value

        #expect(harness.updater.calls.last == .init(current: .loading, outcome: Self.outcome, city: Fixtures.lisbon))
        #expect(harness.viewModel.state == Self.loaded)
    }

    @Test("Try again while a refresh runs keeps the shown forecast")
    func retryDuringRefresh() async {
        let gate = AsyncGate()
        let harness = makeHarness(steps: [.init(Self.outcome), .init(Self.outcome, after: gate)])
        await harness.viewModel.load()
        let refresh = Task { await harness.viewModel.refresh() }
        #expect(await Polling.until { harness.loader.requestedCities.count == 2 })

        await harness.viewModel.retry()

        #expect(harness.viewModel.state == Self.loaded)
        await gate.open()
        await refresh.value
        #expect(harness.loader.requestedCities.count == 2)
    }

    @Test("Refreshing keeps the shown forecast while it fetches and hands it to the updater with the new outcome")
    func refresh() async {
        let gate = AsyncGate()
        let dropped = ForecastLoadOutcome.failed(.offline)
        let refreshed = ForecastState.loaded(LoadedForecast(result: Fixtures.result(Self.forecast, origin: .cache), selectedDay: nil))
        let harness = makeHarness(steps: [.init(Self.outcome), .init(dropped, after: gate)], states: [Self.loaded, refreshed])
        await harness.viewModel.load()

        let refresh = Task { await harness.viewModel.refresh() }
        #expect(await Polling.until { harness.loader.requestedCities.count == 2 })
        #expect(harness.viewModel.state == Self.loaded)
        #expect(!harness.viewModel.isLoading)
        await gate.open()
        await refresh.value

        #expect(harness.updater.calls.last == .init(current: Self.loaded, outcome: dropped, city: Fixtures.lisbon))
        #expect(harness.viewModel.state == refreshed)
    }

    @Test("A cancelled fetch drops its outcome and the next load fetches again")
    func cancelledFetch() async {
        let gate = AsyncGate()
        let harness = makeHarness(steps: [.init(Self.outcome, after: gate), .init(Self.outcome)])
        harness.clock.advance(by: 90)

        let first = Task { await harness.viewModel.load() }
        #expect(await Polling.until { harness.loader.requestedCities.count == 1 })
        first.cancel()
        await gate.open()
        await first.value

        #expect(harness.updater.calls.isEmpty)
        #expect(harness.viewModel.state == .loading)
        #expect(harness.viewModel.now == Fixtures.referenceNow)

        await harness.viewModel.load()

        #expect(harness.loader.requestedCities.count == 2)
        #expect(harness.viewModel.state == Self.loaded)
    }

    @Test("A load the loader reports as cancelled changes nothing")
    func nilOutcome() async {
        let harness = makeHarness(steps: [.init(nil)])
        harness.clock.advance(by: 90)

        await harness.viewModel.load()

        #expect(harness.updater.calls.isEmpty)
        #expect(harness.viewModel.state == .loading)
        #expect(harness.viewModel.now == Fixtures.referenceNow)
    }

    @Test("Choosing a day asks the selector and shows the day it picks")
    func selectDay() async {
        let harness = await loadedHarness(states: [Self.shown(onDay: 1)], selections: [4])

        harness.viewModel.select(day: 2)

        #expect(harness.daySelector.calls == [.init(day: 2, current: 1, dayCount: Self.forecast.days.count)])
        #expect(harness.viewModel.state == Self.shown(onDay: 4))
    }

    @Test("A selection that keeps the shown day does not notify observers")
    func selectionKeepsDay() async {
        let harness = await loadedHarness(states: [Self.shown(onDay: 1)], selections: [1, 3])
        let probe = ObservationProbe()
        probe.track { _ = harness.viewModel.state }

        harness.viewModel.select(day: 1)
        #expect(probe.changeCount == 0)

        harness.viewModel.select(day: 3)
        #expect(probe.changeCount == 1)
        #expect(harness.viewModel.state == Self.shown(onDay: 3))
    }

    @Test("Choosing a day or the week before a forecast is shown does nothing")
    func selectWithoutForecast() {
        let harness = makeHarness()

        harness.viewModel.select(day: 2)
        harness.viewModel.showWeek()

        #expect(harness.daySelector.calls.isEmpty)
        #expect(harness.viewModel.state == .loading)
    }

    @Test("Show week clears the chosen day without asking the selector")
    func showWeek() async {
        let harness = await loadedHarness(states: [Self.shown(onDay: 3)])

        harness.viewModel.showWeek()

        #expect(harness.viewModel.state == Self.loaded)
        #expect(harness.daySelector.calls.isEmpty)
    }

    @Test("Updating the clock evaluates freshness and presents at the new time")
    func updateClock() async {
        let harness = await loadedHarness()
        let later = Fixtures.referenceNow.addingTimeInterval(4 * 60 * 60)
        harness.clock.advance(by: 4 * 60 * 60)
        #expect(harness.viewModel.now == Fixtures.referenceNow)

        harness.viewModel.updateClock()

        #expect(harness.viewModel.now == later)
        #expect(harness.viewModel.presentation == RecordingRankingPresenter.labelledPresentation(for: presentationRequest(now: later)))
        #expect(harness.freshness.calls == [.init(result: Self.result, now: later)])
    }
}
