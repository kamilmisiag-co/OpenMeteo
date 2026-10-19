//
//  RankingViewModel.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Observation
import Utils

@Observable
final class RankingViewModel {
    struct Dependencies {
        let loader: any ForecastLoading
        let updater: any ForecastStateUpdating
        let daySelector: any DaySelecting
        let summarizer: any RankingSummarizing
        let insights: any ActivityInsightProviding
        let freshness: any FreshnessEvaluating
        let dates: any DateProviding
        let presenter: any RankingPresenting
        let detailPresenter: any ActivityDetailPresenting
        let standardDayCount: Int
    }

    let city: City
    let placeholder: RankingPresentation
    private(set) var state: ForecastState = .loading
    private(set) var now: Date

    @ObservationIgnored private let dependencies: Dependencies
    @ObservationIgnored private var isFetching = false

    init(city: City, dependencies: Dependencies) {
        self.city = city
        self.dependencies = dependencies
        placeholder = dependencies.presenter.placeholder(for: city)
        now = dependencies.dates.now()
    }

    var presentation: RankingPresentation? {
        guard let loaded = state.loadedForecast else { return nil }
        let forecast = loaded.result.forecast
        return dependencies.presenter.presentation(
            of: dependencies.summarizer.summary(of: forecast, onDay: loaded.selectedDay),
            in: forecast,
            freshness: freshness(of: loaded.result),
            now: now
        )
    }

    var failure: ServiceFailure? {
        guard case .failed(let failure) = state else { return nil }
        return failure
    }

    var dayCount: Int { state.loadedForecast?.result.forecast.days.count ?? dependencies.standardDayCount }

    var isLoading: Bool { state == .loading }

    func load() async {
        guard isLoading else { return }
        await fetch()
    }

    func retry() async {
        guard !isFetching else { return }
        state = .loading
        await fetch()
    }

    func refresh() async {
        await fetch()
    }

    func select(day: Int?) {
        guard let loaded = state.loadedForecast else { return }
        let selection = dependencies.daySelector.selection(
            afterChoosing: day,
            current: loaded.selectedDay,
            dayCount: loaded.result.forecast.days.count
        )
        show(selection, in: loaded)
    }

    func showWeek() {
        guard let loaded = state.loadedForecast else { return }
        show(nil, in: loaded)
    }

    func updateClock() {
        now = dependencies.dates.now()
    }

    func detail(for activity: Activity) -> ActivityDetail? {
        guard let loaded = state.loadedForecast else { return nil }
        let forecast = loaded.result.forecast
        guard let insight = dependencies.insights.insight(for: activity, in: forecast) else { return nil }
        return dependencies.detailPresenter.detail(for: insight, in: forecast, freshness: freshness(of: loaded.result), now: now)
    }

    private func fetch() async {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }
        let outcome = await dependencies.loader.load(city)
        guard !Task.isCancelled, let outcome else { return }
        updateClock()
        state = dependencies.updater.state(state, applying: outcome, for: city)
    }

    private func show(_ day: Int?, in loaded: LoadedForecast) {
        guard day != loaded.selectedDay else { return }
        state = .loaded(loaded.selecting(day))
    }

    private func freshness(of result: ForecastResult) -> Freshness {
        dependencies.freshness.freshness(of: result, at: now)
    }
}
