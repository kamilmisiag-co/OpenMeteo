//
//  LoadedForecastTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import LogicMocks
import Testing

@Suite("Loaded forecast")
struct LoadedForecastTests {
    private static let result = LogicFixtures.result(LogicFixtures.forecast(days: LogicFixtures.days()), origin: .cache)

    @Test("A selected day inside the forecast's days is kept")
    func dayInsideForecast() {
        #expect(LoadedForecast(result: Self.result, selectedDay: 6).selectedDay == 6)
    }

    @Test("A selected day outside the forecast's days or below zero is dropped, so the whole week is shown", arguments: [-1, 7])
    func dayOutsideForecast(day: Int) {
        let forecast = LoadedForecast(result: Self.result, selectedDay: day)

        #expect(forecast.selectedDay == nil)
        #expect(forecast == LoadedForecast(result: Self.result, selectedDay: nil))
        #expect(forecast.result == Self.result)
    }

    @Test("A forecast without days keeps no selected day")
    func forecastWithoutDays() {
        let empty = LogicFixtures.result(LogicFixtures.forecast(days: []), origin: .live)

        #expect(LoadedForecast(result: empty, selectedDay: 0).selectedDay == nil)
        #expect(LoadedForecast(result: empty, selectedDay: nil).selecting(0).selectedDay == nil)
    }

    @Test("Selecting a day gives a copy with that day selected and the same forecast", arguments: [
        Int?.none, 3,
    ])
    func selectingDay(day: Int?) {
        let shown = LoadedForecast(result: Self.result, selectedDay: 2)

        #expect(shown.selecting(day) == LoadedForecast(result: Self.result, selectedDay: day))
        #expect(shown.selecting(day).selectedDay == day)
        #expect(shown.selecting(day).result == Self.result)
    }
}
