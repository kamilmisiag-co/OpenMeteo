//
//  WMOWeatherCodeMapper.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic

public protocol WeatherCodeMapping: Sendable {
    func condition(forCode code: Int) -> WeatherCondition?
}

public struct WMOWeatherCodeMapper: WeatherCodeMapping {
    public init() {}

    public func condition(forCode code: Int) -> WeatherCondition? {
        switch code {
        case 0, 1: .clear
        case 2: .partlyCloudy
        case 3: .cloudy
        case 45, 48: .fog
        case 51...57: .drizzle
        case 61...67, 80...82: .rain
        case 71...77, 85, 86: .snow
        case 95...99: .thunderstorm
        default: nil
        }
    }
}
