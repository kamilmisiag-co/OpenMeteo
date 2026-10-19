//
//  DayCaptionWriter.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic

struct DayCaptionWriter: DayCaptioning {
    func caption(for activity: Activity, weather: DailyWeather, assessment: DayAssessment?, format: any ForecastFormatting) -> String {
        guard assessment?.blocker != .thunderstorm else {
            return String(localized: .captionBlockedThunderstorm(format.speed(weather.windGustsKmh)))
        }
        let rain = format.percent(weather.precipitationProbability)
        return switch activity {
        case .surfing:
            String(localized: .captionSurfing(format.speed(weather.windSpeedKmh), format.speed(weather.windGustsKmh), rain))
        case .skiing:
            String(localized: .captionSkiing(format.snowfall(weather.snowfallCm), format.temperature(weather.highCelsius)))
        case .outdoorSightseeing:
            String(localized: .captionOutdoorSightseeing(rain, format.temperature(weather.highCelsius)))
        case .indoorSightseeing:
            String(localized: .captionIndoorSightseeing(rain, format.speed(weather.windGustsKmh)))
        }
    }
}
