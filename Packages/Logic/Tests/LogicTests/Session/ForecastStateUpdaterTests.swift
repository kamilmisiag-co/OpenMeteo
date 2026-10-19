//
//  ForecastStateUpdaterTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import LogicMocks
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
    private static let liveFetchedAt = LogicFixtures.referenceNow
    private static let cachedFetchedAt = LogicFixtures.referenceNow.addingTimeInterval(-2 * 60 * 60)
    private static let olderFetchedAt = LogicFixtures.referenceNow.addingTimeInterval(-6 * 60 * 60)
    private static let live = result(days: LogicFixtures.days(), fetchedAt: liveFetchedAt, origin: .live)
    private static let liveOffline = cacheTagged(live)
    private static let cached = result(days: LogicFixtures.days(), fetchedAt: cachedFetchedAt, origin: .cache)
    private static let olderCache = result(days: LogicFixtures.days(from: 16, count: 7), fetchedAt: olderFetchedAt, origin: .cache)
    private static let olderLive = result(days: LogicFixtures.days(from: 18, count: 7), fetchedAt: olderFetchedAt, origin: .live)
    private static let rolled = result(days: LogicFixtures.days(from: 18, count: 7), fetchedAt: liveFetchedAt, origin: .live)
    private static let renamed = result(for: Fixtures.lisboa, days: LogicFixtures.days(), fetchedAt: cachedFetchedAt, origin: .live)
    private static let bergenDays = LogicFixtures.days(in: "Europe/Oslo")
    private static let bergen = result(for: SampleCities.bergen, days: bergenDays, fetchedAt: liveFetchedAt, origin: .live)
    private static let olderBergenCache = result(for: SampleCities.bergen, days: bergenDays, fetchedAt: olderFetchedAt, origin: .cache)
    private static let unshownStates: [ForecastState] = [.loading, .failed(.offline), .failed(.noUpcomingDays), .failed(.unavailable)]

    @Test("A first load shows the forecast with its own origin and no selected day, without carrying a selection over")
    func firstLoad() {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)

        let live = updater.state(.loading, applying: .loaded(Self.live), for: SampleCities.lisbon)
        let cached = updater.state(.loading, applying: .loaded(Self.olderCache), for: SampleCities.lisbon)

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

        let refreshed = updater.state(offline, applying: .loaded(Self.rolled), for: SampleCities.lisbon)
        let unselected = updater.state(online, applying: .loaded(Self.rolled), for: SampleCities.lisbon)

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

        let state = updater.state(shown, applying: .loaded(Self.rolled), for: SampleCities.lisbon)

        #expect(state == .loaded(LoadedForecast(result: Self.rolled, selectedDay: nil)))
        #expect(days.carries == [RecordingDaySelection.Carry(day: 3, previousDays: Self.live.forecast.days, days: Self.rolled.forecast.days)])
    }

    @Test("A refresh of the shown city shows the whole week when the injected selection gives a day outside the new forecast")
    func sameCityRefreshOutsideDays() {
        let days = RecordingDaySelection(selecting: 7)
        let updater = ForecastStateUpdater(days: days)
        let shown = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 3))

        let state = updater.state(shown, applying: .loaded(Self.rolled), for: SampleCities.lisbon)

        #expect(state == .loaded(LoadedForecast(result: Self.rolled, selectedDay: nil)))
        #expect(days.carries == [RecordingDaySelection.Carry(day: 3, previousDays: Self.live.forecast.days, days: Self.rolled.forecast.days)])
    }

    @Test("The shown city is matched by id, so a renamed copy of it still counts as the same city")
    func sameCityById() {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let shown = ForecastState.loaded(LoadedForecast(result: Self.renamed, selectedDay: 2))

        let loaded = updater.state(shown, applying: .loaded(Self.live), for: SampleCities.lisbon)
        let failed = updater.state(shown, applying: .failed(.offline), for: SampleCities.lisbon)
        let cached = updater.state(shown, applying: .loaded(Self.olderCache), for: SampleCities.lisbon)

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

        #expect(updater.state(online, applying: .loaded(Self.bergen), for: SampleCities.bergen) == .loaded(
            LoadedForecast(result: Self.bergen, selectedDay: nil)
        ))
        #expect(updater.state(offline, applying: .loaded(Self.bergen), for: SampleCities.bergen) == .loaded(
            LoadedForecast(result: Self.bergen, selectedDay: nil)
        ))
        #expect(updater.state(online, applying: .loaded(Self.olderBergenCache), for: SampleCities.bergen) == .loaded(
            LoadedForecast(result: Self.olderBergenCache, selectedDay: nil)
        ))
        #expect(days.carries.isEmpty)
    }

    @Test("A cached outcome replaces the shown city's forecast however old it is, carrying the selected day with the injected selection")
    func cacheReplacesForecast() {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let shown = LoadedForecast(result: Self.live, selectedDay: 4)

        let state = updater.state(.loaded(shown), applying: .loaded(Self.olderCache), for: SampleCities.lisbon)

        #expect(state == .loaded(LoadedForecast(result: Self.olderCache, selectedDay: Self.sentinelDay)))
        #expect(days.carries == [
            RecordingDaySelection.Carry(day: 4, previousDays: Self.live.forecast.days, days: Self.olderCache.forecast.days),
        ])
    }

    @Test("A live outcome replaces the shown forecast even when it was fetched before it")
    func olderLiveReplacesForecast() {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let shown = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 2))

        let state = updater.state(shown, applying: .loaded(Self.olderLive), for: SampleCities.lisbon)

        #expect(state == .loaded(LoadedForecast(result: Self.olderLive, selectedDay: Self.sentinelDay)))
        #expect(days.carries == [RecordingDaySelection.Carry(day: 2, previousDays: Self.live.forecast.days, days: Self.olderLive.forecast.days)])
    }

    @Test("An offline failure keeps the shown city's forecast and selected day, tagged as cached")
    func offlineFailureKeepsForecast() {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let online = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 2))
        let offline = ForecastState.loaded(LoadedForecast(result: Self.cached, selectedDay: nil))

        #expect(updater.state(online, applying: .failed(.offline), for: SampleCities.lisbon) == .loaded(
            LoadedForecast(result: Self.liveOffline, selectedDay: 2)
        ))
        #expect(updater.state(offline, applying: .failed(.offline), for: SampleCities.lisbon) == offline)
        #expect(days.carries.isEmpty)
    }

    @Test("An unavailable failure keeps the shown city's forecast, its origin and the selected day, so an earlier offline tag survives")
    func unavailableFailureKeepsForecast() {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let online = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 1))
        let offline = ForecastState.loaded(LoadedForecast(result: Self.cached, selectedDay: 5))
        let tagged = ForecastState.loaded(LoadedForecast(result: Self.liveOffline, selectedDay: 3))

        #expect(updater.state(online, applying: .failed(.unavailable), for: SampleCities.lisbon) == online)
        #expect(updater.state(offline, applying: .failed(.unavailable), for: SampleCities.lisbon) == offline)
        #expect(updater.state(tagged, applying: .failed(.unavailable), for: SampleCities.lisbon) == tagged)
        #expect(days.carries.isEmpty)
    }

    @Test("Finding no upcoming days replaces the shown city's forecast with that failure")
    func noUpcomingDaysReplacesForecast() {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let online = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 1))
        let offline = ForecastState.loaded(LoadedForecast(result: Self.cached, selectedDay: 5))
        let tagged = ForecastState.loaded(LoadedForecast(result: Self.liveOffline, selectedDay: 3))

        #expect(updater.state(online, applying: .failed(.noUpcomingDays), for: SampleCities.lisbon) == .failed(.noUpcomingDays))
        #expect(updater.state(offline, applying: .failed(.noUpcomingDays), for: SampleCities.lisbon) == .failed(.noUpcomingDays))
        #expect(updater.state(tagged, applying: .failed(.noUpcomingDays), for: SampleCities.lisbon) == .failed(.noUpcomingDays))
        #expect(days.carries.isEmpty)
    }

    @Test("A failure while loading another city shows that failure instead of the shown city")
    func anotherCityFailure() {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let online = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 2))
        let offline = ForecastState.loaded(LoadedForecast(result: Self.cached, selectedDay: 5))

        #expect(updater.state(online, applying: .failed(.offline), for: SampleCities.bergen) == .failed(.offline))
        #expect(updater.state(offline, applying: .failed(.offline), for: SampleCities.bergen) == .failed(.offline))
        #expect(days.carries.isEmpty)
    }

    @Test("A failure with no forecast shown becomes that failure")
    func failureWithoutForecast() {
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)

        for current in Self.unshownStates {
            #expect(updater.state(current, applying: .failed(.offline), for: SampleCities.lisbon) == .failed(.offline))
        }
        #expect(days.carries.isEmpty)
    }

    @Test("Every outcome is applied to the current state it is given, so the day that state selects is the one kept or carried over")
    func outcomeUsesCurrentSelection() {
        let day = 3
        let days = RecordingDaySelection(selecting: Self.sentinelDay)
        let updater = ForecastStateUpdater(days: days)
        let current = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: day))

        let offline = updater.state(current, applying: .failed(.offline), for: SampleCities.lisbon)
        let unavailable = updater.state(current, applying: .failed(.unavailable), for: SampleCities.lisbon)
        let refreshed = updater.state(current, applying: .loaded(Self.rolled), for: SampleCities.lisbon)

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

        let state = updater.state(shown, applying: .loaded(Self.rolled), for: SampleCities.lisbon)
        let droppedOut = updater.state(firstDayShown, applying: .loaded(Self.rolled), for: SampleCities.lisbon)

        #expect(state == .loaded(LoadedForecast(result: Self.rolled, selectedDay: 1)))
        #expect(state.loadedForecast?.selectedDay.map { Self.rolled.forecast.days[$0].date } == Self.cached.forecast.days[2].date)
        #expect(droppedOut == .loaded(LoadedForecast(result: Self.rolled, selectedDay: nil)))
    }

    @Test("With the standard selection an older cached outcome replaces the shown days and keeps the selected date")
    func standardOlderCache() {
        let updater = ForecastStateUpdater(days: DateMatchingDaySelection())
        let shown = ForecastState.loaded(LoadedForecast(result: Self.live, selectedDay: 2))

        let state = updater.state(shown, applying: .loaded(Self.olderCache), for: SampleCities.lisbon)

        #expect(state == .loaded(LoadedForecast(result: Self.olderCache, selectedDay: 3)))
        #expect(state.loadedForecast?.selectedDay.map { Self.olderCache.forecast.days[$0].date } == Self.live.forecast.days[2].date)
    }

    private static func result(
        for city: City = SampleCities.lisbon,
        days: [DailyWeather],
        fetchedAt: Date,
        origin: ForecastResult.Origin
    ) -> ForecastResult {
        LogicFixtures.result(LogicFixtures.forecast(city: city, days: days, fetchedAt: fetchedAt), origin: origin)
    }

    private static func cacheTagged(_ result: ForecastResult) -> ForecastResult {
        ForecastResult(forecast: result.forecast, origin: .cache)
    }
}
