//
//  ForecastStateUpdater.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct ForecastStateUpdater: ForecastStateUpdating {
    private let days: any DaySelectionCarrying

    public init(days: any DaySelectionCarrying) {
        self.days = days
    }

    public func state(_ current: ForecastState, applying outcome: ForecastLoadOutcome, for city: City) -> ForecastState {
        let previous = current.loadedForecast.flatMap { $0.result.forecast.city.id == city.id ? $0 : nil }
        switch outcome {
        case .loaded(let result):
            let selectedDay = previous.flatMap {
                days.selection($0.selectedDay, carriedFrom: $0.result.forecast.days, to: result.forecast.days)
            }
            return .loaded(LoadedForecast(result: result, selectedDay: selectedDay))
        case .failed(let failure):
            guard let previous, failure != .noUpcomingDays else { return .failed(failure) }
            return .loaded(failure == .offline ? offline(previous) : previous)
        }
    }

    private func offline(_ forecast: LoadedForecast) -> LoadedForecast {
        LoadedForecast(result: ForecastResult(forecast: forecast.result.forecast, origin: .cache), selectedDay: forecast.selectedDay)
    }
}
