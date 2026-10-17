//
//  ForecastResult.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct ForecastResult: Hashable, Sendable {
    public enum Origin: Hashable, Sendable {
        case live
        case cache
    }

    public let forecast: CityForecast
    public let origin: Origin

    public init(forecast: CityForecast, origin: Origin) {
        self.forecast = forecast
        self.origin = origin
    }
}
