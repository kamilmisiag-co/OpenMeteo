//
//  ForecastDailyField.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

public enum ForecastDailyField: String, CodingKey, CaseIterable, Sendable {
    case time
    case weatherCode = "weather_code"
    case temperatureMax = "temperature_2m_max"
    case temperatureMin = "temperature_2m_min"
    case precipitationProbabilityMax = "precipitation_probability_max"
    case windSpeedMax = "wind_speed_10m_max"
    case windGustsMax = "wind_gusts_10m_max"
    case snowfallSum = "snowfall_sum"

    public var isRequested: Bool {
        self != .time
    }
}
