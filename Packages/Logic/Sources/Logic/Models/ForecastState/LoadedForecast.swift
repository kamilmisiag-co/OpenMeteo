//
//  LoadedForecast.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct LoadedForecast: Hashable, Sendable {
    public let result: ForecastResult
    public let selectedDay: Int?

    public init(result: ForecastResult, selectedDay: Int?) {
        self.result = result
        self.selectedDay = result.forecast.days.validIndex(selectedDay)
    }

    public func selecting(_ day: Int?) -> LoadedForecast {
        LoadedForecast(result: result, selectedDay: day)
    }
}
