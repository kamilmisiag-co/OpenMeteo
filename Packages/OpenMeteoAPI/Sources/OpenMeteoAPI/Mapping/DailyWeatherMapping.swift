//
//  DailyWeatherMapping.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic

public protocol DailyWeatherMapping: Sendable {
    func dailyWeather(from response: ForecastResponseDTO) -> [DailyWeather]
}
