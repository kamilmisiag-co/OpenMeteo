//
//  Fixtures.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Utils
@testable import OpenMeteo

enum Fixtures {
    typealias DayValues = (condition: WeatherCondition, high: Double, low: Double, rain: Double?, wind: Double, gusts: Double, snowfall: Double)

    static let lisbonTimeZone = TimeZone(identifier: "Europe/Lisbon")!
    static let locale = Locale(identifier: "en_GB")
    static let referenceNow = Date(timeIntervalSince1970: 1_792_053_720)

    static let nowhere = City(
        id: 1, name: "Nowhere", region: nil, country: "Atlantis", countryCode: nil,
        latitude: 0, longitude: 0, timeZoneIdentifier: nil
    )

    static let lisbonWeather: [DayValues] = [
        (.partlyCloudy, 23, 16, 0.10, 14, 24, 0),
        (.clear, 24, 16, 0.00, 10, 18, 0),
        (.partlyCloudy, 24, 17, 0.05, 12, 20, 0),
        (.partlyCloudy, 23, 17, 0.10, 15, 26, 0),
        (.cloudy, 22, 16, 0.20, 18, 30, 0),
        (.rain, 19, 15, 0.80, 32, 55, 0),
        (.rain, 20, 15, 0.50, 24, 40, 0),
    ]

    static func days(_ values: [DayValues], startingAt start: Date = referenceNow, in timeZone: TimeZone = lisbonTimeZone) -> [DailyWeather] {
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
                snowfallCm: value.snowfall,
                snowDepthCm: nil
            )
        }
    }

    static func outlook(_ activity: Activity, scores: [Int?], blocker: Factor.Kind = .snowfall, factors: [Factor] = []) -> ActivityOutlook {
        let assessments = scores.map { score in
            score.map { DayAssessment(score: $0, effects: [:]) } ?? DayAssessment(blockedBy: blocker, effects: [:])
        }
        return ActivityOutlook(activity: activity, days: assessments, factors: factors)
    }

    static let lisbonOutlooks: [ActivityOutlook] = [
        outlook(.surfing, scores: [80, 88, 92, 84, 76, 28, 66], factors: [
            Factor(kind: .rain, effect: .hurts, days: [5, 6]),
            Factor(kind: .wind, effect: .hurts, days: [5]),
            Factor(kind: .temperature, effect: .helps, days: Array(0...6)),
        ]),
        outlook(.outdoorSightseeing, scores: [78, 90, 88, 80, 72, 40, 64], factors: [
            Factor(kind: .rain, effect: .hurts, days: [5, 6]),
            Factor(kind: .temperature, effect: .helps, days: Array(0...6)),
            Factor(kind: .wind, effect: .helps, days: Array(0...4)),
        ]),
        outlook(.indoorSightseeing, scores: [40, 32, 35, 42, 50, 76, 58], factors: [
            Factor(kind: .temperature, effect: .hurts, days: Array(0...4)),
            Factor(kind: .rain, effect: .helps, days: [5, 6]),
            Factor(kind: .wind, effect: .helps, days: [5]),
        ]),
        outlook(.skiing, scores: Array(repeating: nil, count: 7), factors: [
            Factor(kind: .snowfall, effect: .hurts, days: Array(0...6)),
            Factor(kind: .temperature, effect: .hurts, days: Array(0...6)),
        ]),
    ]

    static func lisbonForecast(fetchedAt: Date = referenceNow) -> CityForecast {
        CityForecast(city: PreviewCities.lisbon, days: days(lisbonWeather), outlooks: lisbonOutlooks, fetchedAt: fetchedAt)
    }

    static func result(_ forecast: CityForecast, origin: ForecastResult.Origin = .live) -> ForecastResult {
        ForecastResult(forecast: forecast, origin: origin)
    }
}
