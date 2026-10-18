//
//  ForecastStateUpdaterTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import Synchronization
import Testing

@Suite("Forecast state updater")
struct ForecastStateUpdaterTests {
    private final class RecordingDaySelection: DaySelectionCarrying {
        struct Carry: Hashable {
            let day: Int?
            let previousDays: [DailyWeather]
            let days: [DailyWeather]
        }

        private let selected: Int?
        private let received = Mutex<[Carry]>([])

        init(selecting selected: Int?) {
            self.selected = selected
        }

        var carries: [Carry] {
            received.withLock { $0 }
        }

        func selection(_ day: Int?, carriedFrom previousDays: [DailyWeather], to days: [DailyWeather]) -> Int? {
            received.withLock { $0.append(Carry(day: day, previousDays: previousDays, days: days)) }
            return selected
        }
    }

    private static let sentinelDay = 4
    private static let liveFetchedAt = Fixtures.referenceNow
    private static let cachedFetchedAt = Fixtures.referenceNow.addingTimeInterval(-2 * 60 * 60)
    private static let olderFetchedAt = Fixtures.referenceNow.addingTimeInterval(-6 * 60 * 60)
    private static let live = result(days: Fixtures.lisbonDays(from: 17, count: 7), fetchedAt: liveFetchedAt, origin: .live)
    private static let liveOffline = cacheTagged(live)
    private static let cached = result(days: Fixtures.lisbonDays(from: 17, count: 7), fetchedAt: cachedFetchedAt, origin: .cache)
    private static let olderCache = result(days: Fixtures.lisbonDays(from: 16, count: 7), fetchedAt: olderFetchedAt, origin: .cache)
    private static let sameAgeCache = result(days: Fixtures.lisbonDays(from: 18, count: 7), fetchedAt: cachedFetchedAt, origin: .cache)
    private static let newerCache = result(days: Fixtures.lisbonDays(from: 18, count: 7), fetchedAt: liveFetchedAt, origin: .cache)
    private static let olderLive = result(days: Fixtures.lisbonDays(from: 18, count: 7), fetchedAt: olderFetchedAt, origin: .live)
    private static let rolled = result(days: Fixtures.lisbonDays(from: 18, count: 7), fetchedAt: liveFetchedAt, origin: .live)
    private static let renamed = result(for: Fixtures.lisboa, days: Fixtures.lisbonDays(from: 17, count: 7), fetchedAt: cachedFetchedAt, origin: .live)
    private static let bergenDays = Fixtures.week(startingOn: Fixtures.date(2026, 10, 17, in: "Europe/Oslo"), in: "Europe/Oslo")
    private static let bergen = result(for: Fixtures.bergen, days: bergenDays, fetchedAt: liveFetchedAt, origin: .live)
    private static let olderBergenCache = result(for: Fixtures.bergen, days: bergenDays, fetchedAt: olderFetchedAt, origin: .cache)
    private static let unshownStates: [ForecastState] = [.loading, .failed(.offline), .failed(.noUpcomingDays), .failed(.unavailable)]
    private static let cacheReplacements: [(LoadedForecast, ForecastResult)] = [
        (LoadedForecast(result: live, selectedDay: 4), cached),
        (LoadedForecast(result: live, selectedDay: 4), olderCache),
        (LoadedForecast(result: cached, selectedDay: 1), olderCache),
        (LoadedForecast(result: liveOffline, selectedDay: nil), olderCache),
        (LoadedForecast(result: cached, selectedDay: 1), sameAgeCache),
        (LoadedForecast(result: cached, selectedDay: 1), newerCache),
        (LoadedForecast(result: live, selectedDay: 2), newerCache),
    ]

    @Test("A first load shows the forecast with its own origin and no selected day, without carrying a selection over", arguments: unshownStates)
    func firstLoad(current: ForecastState) {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)

        let live = updater.state(current, applying: .loaded(Self.live), for: Fixtures.lisbon)
        let cached = updater.state(current, applying: .loaded(Self.olderCache), for: Fixtures.lisbon)

        #expect(live == .loaded(LoadedForecast(result: Self.live, selectedDay: nil)))
        #expect(cached == .loaded(LoadedForecast(result: Self.olderCache, selectedDay: nil)))
        #expect(days.carries.isEmpty)
    }

    @Test("A refresh of the shown city carries the selected day over with the injected selection and shows the live forecast")
    func sameCityRefresh() {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let offline = ForecastState.loaded(LoadedForecast(result: Self.cached, selectedDay: 6))
        let online = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: nil))

        let refreshed = updater.state(offline, applying: .loaded(Self.rolled), for: Fixtures.lisbon)
        let unselected = updater.state(online, applying: .loaded(Self.rolled), for: Fixtures.lisbon)

        #expect(refreshed == .loaded(LoadedForecast(result: Self.rolled, selectedDay: Self.sentinelDay)))
        #expect(refreshed.loadedForecast?.result.origin == .live)
        #expect(unselected == .loaded(LoadedForecast(result: Self.rolled, selectedDay: Self.sentinelDay)))
        #expect(days.carries == [
            RecordingDaySelection.Carry(day: 6, previousDays: Self.cached.forecast.days, days: Self.rolled.forecast.days),
            RecordingDaySelection.Carry(day: nil, previousDays: Self.live.forecast.days, days: Self.rolled.forecast.days),
        ])
    }

    @Test("A refresh of the shown city shows the whole week when the injected selection drops the day")
    func sameCityRefreshDroppingDay() {
        let days = RecordingDaySelection(selecting: nil)
        let updater = ForecastStateUpdater(days: days)
        let shown = ForecastState.loaded(LoadedForecast(result: Self.liveOffline, selectedDay: 3))

        let state = updater.state(shown, applying: .loaded(Self.rolled), for: Fixtures.lisbon)

        #expect(state == .loaded(LoadedForecast(result: Self.rolled, selectedDay: nil)))
        #expect(days.carries == [RecordingDaySelection.Carry(day: 3, previousDays: Self.live.forecast.days, days: Self.rolled.forecast.days)])
    }

    @Test("A refresh of the shown city shows the whole week when the injected selection gives a day outside the new forecast", arguments: [
        -1, 7, 42,
    ])
    func sameCityRefreshOutsideDays(selected: Int) {
        let days = RecordingDaySelection(selecting: selected)
        let updater = ForecastStateUpdater(days: days)
        let shown = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 3))

        let state = updater.state(shown, applying: .loaded(Self.rolled), for: Fixtures.lisbon)

        #expect(state == .loaded(LoadedForecast(result: Self.rolled, selectedDay: nil)))
        #expect(days.carries == [RecordingDaySelection.Carry(day: 3, previousDays: Self.live.forecast.days, days: Self.rolled.forecast.days)])
    }

    @Test("The shown city is matched by id, so a renamed copy of it still counts as the same city")
    func sameCityById() {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let shown = ForecastState.loaded(LoadedForecast(result: Self.renamed, selectedDay: 2))

        let loaded = updater.state(shown, applying: .loaded(Self.live), for: Fixtures.lisbon)
        let failed = updater.state(shown, applying: .failed(.offline), for: Fixtures.lisbon)
        let cached = updater.state(shown, applying: .loaded(Self.olderCache), for: Fixtures.lisbon)

        #expect(loaded == .loaded(LoadedForecast(result: Self.live, selectedDay: Self.sentinelDay)))
        #expect(failed == .loaded(LoadedForecast(result: Self.cacheTagged(Self.renamed), selectedDay: 2)))
        #expect(cached == .loaded(LoadedForecast(result: Self.olderCache, selectedDay: Self.sentinelDay)))
        #expect(days.carries == [
            RecordingDaySelection.Carry(day: 2, previousDays: Self.renamed.forecast.days, days: Self.live.forecast.days),
            RecordingDaySelection.Carry(day: 2, previousDays: Self.renamed.forecast.days, days: Self.olderCache.forecast.days),
        ])
    }

    @Test("Loading another city shows its whole week with its own origin, even an older cached copy, without carrying the selected day over")
    func anotherCityLoad() {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let online = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 2))
        let offline = ForecastState.loaded(LoadedForecast(result: Self.cached, selectedDay: 5))

        #expect(updater.state(online, applying: .loaded(Self.bergen), for: Fixtures.bergen) == .loaded(
            LoadedForecast(result: Self.bergen, selectedDay: nil)
        ))
        #expect(updater.state(offline, applying: .loaded(Self.bergen), for: Fixtures.bergen) == .loaded(
            LoadedForecast(result: Self.bergen, selectedDay: nil)
        ))
        #expect(updater.state(online, applying: .loaded(Self.olderBergenCache), for: Fixtures.bergen) == .loaded(
            LoadedForecast(result: Self.olderBergenCache, selectedDay: nil)
        ))
        #expect(days.carries.isEmpty)
    }

    @Test("A cached outcome replaces the shown city's forecast however old it is, carrying the selected day with the injected selection", arguments: cacheReplacements)
    func cacheReplacesForecast(shown: LoadedForecast, cache: ForecastResult) {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)

        let state = updater.state(.loaded(shown), applying: .loaded(cache), for: Fixtures.lisbon)

        #expect(state == .loaded(LoadedForecast(result: cache, selectedDay: Self.sentinelDay)))
        #expect(days.carries == [
            RecordingDaySelection.Carry(day: shown.selectedDay, previousDays: shown.result.forecast.days, days: cache.forecast.days),
        ])
    }

    @Test("A live outcome replaces the shown forecast even when it was fetched before it")
    func olderLiveReplacesForecast() {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let shown = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 2))

        let state = updater.state(shown, applying: .loaded(Self.olderLive), for: Fixtures.lisbon)

        #expect(state == .loaded(LoadedForecast(result: Self.olderLive, selectedDay: Self.sentinelDay)))
        #expect(days.carries == [RecordingDaySelection.Carry(day: 2, previousDays: Self.live.forecast.days, days: Self.olderLive.forecast.days)])
    }

    @Test("An offline failure keeps the shown city's forecast and selected day, tagged as cached")
    func offlineFailureKeepsForecast() {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let online = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 2))
        let offline = ForecastState.loaded(LoadedForecast(result: Self.cached, selectedDay: nil))

        #expect(updater.state(online, applying: .failed(.offline), for: Fixtures.lisbon) == .loaded(
            LoadedForecast(result: Self.liveOffline, selectedDay: 2)
        ))
        #expect(updater.state(offline, applying: .failed(.offline), for: Fixtures.lisbon) == offline)
        #expect(days.carries.isEmpty)
    }

    @Test("An unavailable failure keeps the shown city's forecast, its origin and the selected day, so an earlier offline tag survives")
    func unavailableFailureKeepsForecast() {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let online = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 1))
        let offline = ForecastState.loaded(LoadedForecast(result: Self.cached, selectedDay: 5))
        let tagged = ForecastState.loaded(LoadedForecast(result: Self.liveOffline, selectedDay: 3))

        #expect(updater.state(online, applying: .failed(.unavailable), for: Fixtures.lisbon) == online)
        #expect(updater.state(offline, applying: .failed(.unavailable), for: Fixtures.lisbon) == offline)
        #expect(updater.state(tagged, applying: .failed(.unavailable), for: Fixtures.lisbon) == tagged)
        #expect(days.carries.isEmpty)
    }

    @Test("Finding no upcoming days replaces the shown city's forecast with that failure")
    func noUpcomingDaysReplacesForecast() {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let online = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 1))
        let offline = ForecastState.loaded(LoadedForecast(result: Self.cached, selectedDay: 5))
        let tagged = ForecastState.loaded(LoadedForecast(result: Self.liveOffline, selectedDay: 3))

        #expect(updater.state(online, applying: .failed(.noUpcomingDays), for: Fixtures.lisbon) == .failed(.noUpcomingDays))
        #expect(updater.state(offline, applying: .failed(.noUpcomingDays), for: Fixtures.lisbon) == .failed(.noUpcomingDays))
        #expect(updater.state(tagged, applying: .failed(.noUpcomingDays), for: Fixtures.lisbon) == .failed(.noUpcomingDays))
        #expect(days.carries.isEmpty)
    }

    @Test("A failure while loading another city shows that failure instead of the shown city", arguments: [
        ServiceFailure.offline, .noUpcomingDays, .unavailable,
    ])
    func anotherCityFailure(failure: ServiceFailure) {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let online = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 2))
        let offline = ForecastState.loaded(LoadedForecast(result: Self.cached, selectedDay: 5))

        #expect(updater.state(online, applying: .failed(failure), for: Fixtures.bergen) == .failed(failure))
        #expect(updater.state(offline, applying: .failed(failure), for: Fixtures.bergen) == .failed(failure))
        #expect(days.carries.isEmpty)
    }

    @Test("A failure with no forecast shown becomes that failure", arguments: [
        ServiceFailure.offline, .noUpcomingDays, .unavailable,
    ])
    func failureWithoutForecast(failure: ServiceFailure) {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)

        for current in Self.unshownStates {
            #expect(updater.state(current, applying: .failed(failure), for: Fixtures.lisbon) == .failed(failure))
        }
        #expect(days.carries.isEmpty)
    }

    @Test("Every outcome is applied to the current state it is given, so the day that state selects is the one kept or carried over", arguments: [
        Int?.none, 0, 3, 6,
    ])
    func outcomeUsesCurrentSelection(day: Int?) {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let current = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: day))

        let offline = updater.state(current, applying: .failed(.offline), for: Fixtures.lisbon)
        let unavailable = updater.state(current, applying: .failed(.unavailable), for: Fixtures.lisbon)
        let refreshed = updater.state(current, applying: .loaded(Self.rolled), for: Fixtures.lisbon)

        #expect(offline == .loaded(LoadedForecast(result: Self.liveOffline, selectedDay: day)))
        #expect(unavailable == .loaded(LoadedForecast(result: Self.live, selectedDay: day)))
        #expect(refreshed == .loaded(LoadedForecast(result: Self.rolled, selectedDay: Self.sentinelDay)))
        #expect(days.carries == [RecordingDaySelection.Carry(day: day, previousDays: Self.live.forecast.days, days: Self.rolled.forecast.days)])
    }

    @Test("With the standard selection a refresh whose days moved on by one keeps the same selected date")
    func standardRolledRefresh() {
        let updater = ForecastStateUpdater(days: DateMatchingDaySelection())
        let shown = ForecastState.loaded(LoadedForecast(result: Self.cached, selectedDay: 2))
        let firstDayShown = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 0))

        let state = updater.state(shown, applying: .loaded(Self.rolled), for: Fixtures.lisbon)
        let droppedOut = updater.state(firstDayShown, applying: .loaded(Self.rolled), for: Fixtures.lisbon)

        #expect(state == .loaded(LoadedForecast(result: Self.rolled, selectedDay: 1)))
        #expect(state.loadedForecast?.selectedDay.map { Self.rolled.forecast.days[$0].date } == Self.cached.forecast.days[2].date)
        #expect(droppedOut == .loaded(LoadedForecast(result: Self.rolled, selectedDay: nil)))
    }

    @Test("With the standard selection an older cached outcome replaces the shown days and keeps the selected date")
    func standardOlderCache() {
        let updater = ForecastStateUpdater(days: DateMatchingDaySelection())
        let shown = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 2))

        let state = updater.state(shown, applying: .loaded(Self.olderCache), for: Fixtures.lisbon)

        #expect(state == .loaded(LoadedForecast(result: Self.olderCache, selectedDay: 3)))
        #expect(state.loadedForecast?.selectedDay.map { Self.olderCache.forecast.days[$0].date } == Self.live.forecast.days[2].date)
    }

    @Test("With the standard selection loading another city or loading for the first time shows the whole week")
    func standardWholeWeek() {
        let updater = ForecastStateUpdater(days: DateMatchingDaySelection())
        let lisbon = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 2))

        #expect(updater.state(lisbon, applying: .loaded(Self.bergen), for: Fixtures.bergen) == .loaded(
            LoadedForecast(result: Self.bergen, selectedDay: nil)
        ))
        #expect(updater.state(.loading, applying: .loaded(Self.live), for: Fixtures.lisbon) == .loaded(
            LoadedForecast(result: Self.live, selectedDay: nil)
        ))
    }

    private static func result(
        for city: City = Fixtures.lisbon,
        days: [DailyWeather],
        fetchedAt: Date,
        origin: ForecastResult.Origin
    ) -> ForecastResult {
        ForecastResult(forecast: CityForecast(city: city, days: days, outlooks: [], fetchedAt: fetchedAt), origin: origin)
    }

    private static func cacheTagged(_ result: ForecastResult) -> ForecastResult {
        ForecastResult(forecast: result.forecast, origin: .cache)
    }
}
