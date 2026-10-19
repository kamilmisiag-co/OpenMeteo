//
//  WeatherColumn.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Foundation
import Logic

struct WeatherColumn {
    let symbolName: String
    let conditionTitle: String
    let high: String
    let low: String

    init(weather: DailyWeather, format: any ForecastFormatting) {
        symbolName = weather.condition.systemImage
        conditionTitle = String(localized: weather.condition.title)
        high = format.temperature(weather.highCelsius)
        low = format.temperature(weather.lowCelsius)
    }
}
