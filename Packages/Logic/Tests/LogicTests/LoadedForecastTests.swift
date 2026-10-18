//
//  LoadedForecastTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Testing

@Suite("Loaded forecast")
struct LoadedForecastTests {
    private static let result = forecastResult(.cache, days: Fixtures.lisbonDays(from: 17, count: 7))
    private static let outsideDays = [-1, -42, 7, 42, Int.min, Int.max]

    @Test("A selected day inside the forecast's days is kept", arguments: 0..<7)
    func dayInsideForecast(day: Int) {
        #expect(LoadedForecast(result: Self.result, selectedDay: day).selectedDay == day)
    }

    @Test("No selected day stays no selected day")
    func noSelectedDay() {
        #expect(LoadedForecast(result: Self.result, selectedDay: nil).selectedDay == nil)
    }

    @Test("A selected day outside the forecast's days or below zero is dropped, so the whole week is shown", arguments: outsideDays)
    func dayOutsideForecast(day: Int) {
        let forecast = LoadedForecast(result: Self.result, selectedDay: day)

        #expect(forecast.selectedDay == nil)
        #expect(forecast == LoadedForecast(result: Self.result, selectedDay: nil))
        #expect(forecast.result == Self.result)
    }

    @Test("A forecast without days keeps no selected day", arguments: [0, 1, -1])
    func forecastWithoutDays(day: Int) {
        let empty = Self.forecastResult(.live, days: [])

        #expect(LoadedForecast(result: empty, selectedDay: day).selectedDay == nil)
        #expect(LoadedForecast(result: empty, selectedDay: nil).selecting(day).selectedDay == nil)
    }

    @Test("Selecting a day gives a copy with that day selected and the same forecast", arguments: [
        Int?.none, 0, 3, 6,
    ])
    func selectingDay(day: Int?) {
        let shown = LoadedForecast(result: Self.result, selectedDay: 2)

        #expect(shown.selecting(day) == LoadedForecast(result: Self.result, selectedDay: day))
        #expect(shown.selecting(day).selectedDay == day)
        #expect(shown.selecting(day).result == Self.result)
    }

    @Test("Selecting a day outside the forecast's days or below zero shows the whole week", arguments: outsideDays)
    func selectingDayOutsideForecast(day: Int) {
        let shown = LoadedForecast(result: Self.result, selectedDay: 2)

        #expect(shown.selecting(day) == LoadedForecast(result: Self.result, selectedDay: nil))
        #expect(shown.selecting(day).selectedDay == nil)
    }

    @Test("Selecting keeps the forecast's origin, live or cached", arguments: [ForecastResult.Origin.live, .cache])
    func selectingKeepsOrigin(origin: ForecastResult.Origin) {
        let result = Self.forecastResult(origin, days: Fixtures.lisbonDays(from: 17, count: 7))
        let shown = LoadedForecast(result: result, selectedDay: nil)

        #expect(shown.selecting(4) == LoadedForecast(result: result, selectedDay: 4))
        #expect(shown.selecting(4).result.origin == origin)
        #expect(shown.selecting(nil) == shown)
    }

    private static func forecastResult(_ origin: ForecastResult.Origin, days: [DailyWeather]) -> ForecastResult {
        ForecastResult(
            forecast: CityForecast(city: Fixtures.lisbon, days: days, outlooks: [], fetchedAt: Fixtures.referenceNow),
            origin: origin
        )
    }
}
