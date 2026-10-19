//
//  PreviewForecasts.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

#if DEBUG
import Foundation
import Logic
import Utils

nonisolated enum PreviewForecasts {
    private typealias DayValues = (condition: WeatherCondition, high: Double, low: Double, rain: Double, wind: Double, gusts: Double)

    static let referenceNow = Date(timeIntervalSince1970: 1_792_053_720)

    private static let lisbonWeather: [DayValues] = [
        (.partlyCloudy, 23, 16, 0.10, 14, 24),
        (.clear, 24, 16, 0.00, 10, 18),
        (.partlyCloudy, 24, 17, 0.05, 12, 20),
        (.partlyCloudy, 23, 17, 0.10, 15, 26),
        (.cloudy, 22, 16, 0.20, 18, 30),
        (.rain, 19, 15, 0.80, 32, 55),
        (.rain, 20, 15, 0.50, 24, 40),
    ]

    private static let bergenWeather: [DayValues] = [
        (.rain, 11, 7, 0.90, 30, 55),
        (.rain, 10, 6, 0.70, 26, 48),
        (.rain, 12, 8, 0.85, 34, 60),
        (.cloudy, 11, 7, 0.40, 22, 40),
        (.rain, 10, 6, 0.75, 28, 52),
        (.rain, 9, 5, 0.95, 36, 62),
        (.rain, 11, 7, 0.80, 30, 54),
    ]

    static func forecast(for city: City, startingAt start: Date, fetchedAt: Date, fallbackTimeZone: TimeZone) -> CityForecast {
        let isBergen = city.id == PreviewCities.bergen.id
        return CityForecast(
            city: city,
            days: days(isBergen ? bergenWeather : lisbonWeather, startingAt: start, in: city.timeZone ?? fallbackTimeZone),
            outlooks: isBergen ? PreviewOutlooks.bergen : PreviewOutlooks.lisbon,
            fetchedAt: fetchedAt
        )
    }

    private static func days(_ values: [DayValues], startingAt start: Date, in timeZone: TimeZone) -> [DailyWeather] {
        let calendar = Calendar.gregorian(timeZone: timeZone)
        let firstDay = calendar.startOfDay(for: start)
        return values.enumerated().map { offset, value in
            DailyWeather(
                date: calendar.date(byAdding: .day, value: offset, to: firstDay) ?? firstDay,
                condition: value.condition,
                highCelsius: value.high,
                lowCelsius: value.low,
                precipitationProbability: value.rain,
                windSpeedKmh: value.wind,
                windGustsKmh: value.gusts,
                snowfallCm: 0,
                snowDepthCm: nil
            )
        }
    }
}
#endif
