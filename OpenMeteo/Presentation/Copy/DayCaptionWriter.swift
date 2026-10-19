//
//  DayCaptionWriter.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Utils

protocol DayCaptioning {
    func caption(for activity: Activity, weather: DailyWeather, assessment: DayAssessment?, format: any ForecastFormatting) -> String
}

extension DayCaptioning {
    func caption(onDay day: Int, of outlook: ActivityOutlook, weather: DailyWeather, format: any ForecastFormatting) -> String {
        caption(for: outlook.activity, weather: weather, assessment: outlook.days.element(at: day), format: format)
    }
}

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
