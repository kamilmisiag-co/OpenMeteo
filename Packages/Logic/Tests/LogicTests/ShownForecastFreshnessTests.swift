//
//  ShownForecastFreshnessTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import Testing

@Suite("Shown forecast freshness")
struct ShownForecastFreshnessTests {
    private static let staleAfterSeconds = StandardRules.staleAfter / .seconds(1)
    private static let fetchedAt = Fixtures.referenceNow
    private static let olderCachedAt = fetchedAt.addingTimeInterval(-6 * 60 * 60)
    private static let midway = fetchedAt.addingTimeInterval(staleAfterSeconds / 2)
    private static let atThreshold = fetchedAt.addingTimeInterval(staleAfterSeconds)
    private static let pastThreshold = atThreshold.addingTimeInterval(1)
    private static let live = result(fetchedAt: fetchedAt, origin: .live)
    private static let olderCache = result(fetchedAt: olderCachedAt, origin: .cache)

    private let evaluator = FreshnessEvaluator(staleAfter: StandardRules.staleAfter)
    private let updater = ForecastStateUpdater(days: DateMatchingDaySelection())

    @Test("A live forecast the updater shows is fresh at exactly the stale threshold and stale since its fetch a second after it")
    func liveForecast() throws {
        let shown = try #require(updater.state(.loading, applying: .loaded(Self.live), for: Fixtures.lisbon).loadedForecast)

        #expect(evaluator.freshness(of: shown.result, at: Self.midway) == .fresh)
        #expect(evaluator.freshness(of: shown.result, at: Self.atThreshold) == .fresh)
        #expect(evaluator.freshness(of: shown.result, at: Self.pastThreshold) == .stale(since: Self.fetchedAt))
    }

    @Test("A live forecast kept through an unavailable failure is still judged fresh or stale")
    func liveForecastKeptThroughUnavailable() throws {
        let current = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 2))
        let shown = try #require(updater.state(current, applying: .failed(.unavailable), for: Fixtures.lisbon).loadedForecast)

        #expect(evaluator.freshness(of: shown.result, at: Self.midway) == .fresh)
        #expect(evaluator.freshness(of: shown.result, at: Self.pastThreshold) == .stale(since: Self.fetchedAt))
    }

    @Test("A live forecast kept through an offline failure is offline since it was fetched, whatever its age")
    func liveForecastKeptOffline() throws {
        let current = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 2))
        let shown = try #require(updater.state(current, applying: .failed(.offline), for: Fixtures.lisbon).loadedForecast)

        #expect(shown.result.origin == .cache)
        #expect(evaluator.freshness(of: shown.result, at: Self.midway) == .offline(since: Self.fetchedAt))
        #expect(evaluator.freshness(of: shown.result, at: Self.pastThreshold) == .offline(since: Self.fetchedAt))
    }

    @Test("An older cached outcome replaces a shown live forecast and is offline since its own fetch, whatever its age")
    func olderCacheReplacesLiveForecast() throws {
        let current = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: nil))
        let shown = try #require(updater.state(current, applying: .loaded(Self.olderCache), for: Fixtures.lisbon).loadedForecast)

        #expect(shown.result == Self.olderCache)
        #expect(evaluator.freshness(of: shown.result, at: Self.midway) == .offline(since: Self.olderCachedAt))
        #expect(evaluator.freshness(of: shown.result, at: Self.pastThreshold) == .offline(since: Self.olderCachedAt))
    }

    @Test("An offline tag survives a later unavailable failure, so the forecast stays offline since it was fetched")
    func offlineTagSurvivesUnavailable() throws {
        let current = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 1))
        let offline = updater.state(current, applying: .failed(.offline), for: Fixtures.lisbon)
        let shown = try #require(updater.state(offline, applying: .failed(.unavailable), for: Fixtures.lisbon).loadedForecast)

        #expect(shown.selectedDay == 1)
        #expect(evaluator.freshness(of: shown.result, at: Self.midway) == .offline(since: Self.fetchedAt))
    }

    @Test("A live refresh after an offline failure replaces the shown forecast and is fresh when the old one would be stale")
    func liveRefreshAfterOffline() throws {
        let current = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: nil))
        let offline = updater.state(current, applying: .failed(.offline), for: Fixtures.lisbon)
        let refreshed = Self.result(fetchedAt: Self.atThreshold, origin: .live)
        let shown = try #require(updater.state(offline, applying: .loaded(refreshed), for: Fixtures.lisbon).loadedForecast)

        #expect(shown.result == refreshed)
        #expect(evaluator.freshness(of: Self.live, at: Self.pastThreshold) == .stale(since: Self.fetchedAt))
        #expect(evaluator.freshness(of: shown.result, at: Self.pastThreshold) == .fresh)
    }

    private static func result(fetchedAt: Date, origin: ForecastResult.Origin) -> ForecastResult {
        ForecastResult(
            forecast: CityForecast(city: Fixtures.lisbon, days: Fixtures.lisbonDays(from: 17, count: 7), outlooks: [], fetchedAt: fetchedAt),
            origin: origin
        )
    }
}
