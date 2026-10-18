//
//  ForecastStateTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Testing

@Suite("Forecast state")
struct ForecastStateTests {
    @Test("Only a loaded state has a loaded forecast", arguments: [
        ForecastState.loading, .failed(.offline), .failed(.noUpcomingDays), .failed(.unavailable),
    ])
    func noLoadedForecast(state: ForecastState) {
        #expect(state.loadedForecast == nil)
    }

    @Test("A loaded state gives back the forecast it holds, with its origin and selected day", arguments: [
        ForecastResult.Origin.live, .cache,
    ])
    func loadedForecast(origin: ForecastResult.Origin) {
        let result = ForecastResult(
            forecast: CityForecast(city: Fixtures.lisbon, days: Fixtures.lisbonDays(from: 17, count: 7), outlooks: [], fetchedAt: Fixtures.referenceNow),
            origin: origin
        )
        let forecast = LoadedForecast(result: result, selectedDay: 3)

        #expect(ForecastState.loaded(forecast).loadedForecast == forecast)
        #expect(ForecastState.loaded(forecast).loadedForecast?.result.origin == origin)
        #expect(ForecastState.loaded(forecast).loadedForecast?.selectedDay == 3)
    }
}
