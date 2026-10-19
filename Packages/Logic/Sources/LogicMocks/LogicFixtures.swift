//
//  LogicFixtures.swift
//  LogicMocks
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Foundation
import Logic
import Utils
import UtilsMocks

public enum LogicFixtures {
    public static let referenceNow = date(day: 17, hour: 9, minute: 30, in: "Europe/Lisbon")

    public static func day(
        on date: Date = referenceNow,
        condition: WeatherCondition = .clear,
        high: Double = 20,
        low: Double = 12,
        rain: Double? = 0,
        wind: Double = 10,
        gusts: Double = 15,
        snowfall: Double = 0,
        snowDepth: Double? = nil
    ) -> DailyWeather {
        DailyWeather(
            date: date,
            condition: condition,
            highCelsius: high,
            lowCelsius: low,
            precipitationProbability: rain,
            windSpeedKmh: wind,
            windGustsKmh: gusts,
            snowfallCm: snowfall,
            snowDepthCm: snowDepth
        )
    }

    public static func days(from firstDay: Int = 17, count: Int = 7, in timeZoneIdentifier: String = "Europe/Lisbon") -> [DailyWeather] {
        let gregorian = calendar(in: timeZoneIdentifier)
        let first = date(day: firstDay, in: timeZoneIdentifier)
        return (0..<count).map { offset in
            day(on: gregorian.date(byAdding: .day, value: offset, to: first)!)
        }
    }

    public static func scored(_ score: Int, effects: [Factor.Kind: Factor.Effect] = [:]) -> DayAssessment {
        DayAssessment(score: score, effects: effects)
    }

    public static func blocked(_ kind: Factor.Kind, effects: [Factor.Kind: Factor.Effect] = [:]) -> DayAssessment {
        DayAssessment(blockedBy: kind, effects: effects)
    }

    public static func outlook(_ activity: Activity = .surfing, days: [DayAssessment], factors: [Factor] = []) -> ActivityOutlook {
        ActivityOutlook(activity: activity, days: days, factors: factors)
    }

    public static func outlook(
        _ activity: Activity = .surfing,
        scores: [Int?],
        blocker: Factor.Kind = .rain,
        factors: [Factor] = []
    ) -> ActivityOutlook {
        outlook(activity, days: scores.map { score in score.map { scored($0) } ?? blocked(blocker) }, factors: factors)
    }

    public static func forecast(
        _ outlooks: [ActivityOutlook] = [],
        city: City = SampleCities.lisbon,
        days: [DailyWeather]? = nil,
        fetchedAt: Date = referenceNow
    ) -> CityForecast {
        CityForecast(
            city: city,
            days: days ?? Self.days(count: outlooks.map(\.days.count).max() ?? 0, in: city.timeZoneIdentifier ?? "UTC"),
            outlooks: outlooks,
            fetchedAt: fetchedAt
        )
    }

    public static func result(_ forecast: CityForecast = forecast(), origin: ForecastResult.Origin) -> ForecastResult {
        ForecastResult(forecast: forecast, origin: origin)
    }

    private static func date(day: Int, hour: Int = 0, minute: Int = 0, in timeZoneIdentifier: String) -> Date {
        calendar(in: timeZoneIdentifier).date(year: 2026, month: 10, day: day, hour: hour, minute: minute)
    }

    private static func calendar(in timeZoneIdentifier: String) -> Calendar {
        Calendar.gregorian(timeZone: TimeZone(identifier: timeZoneIdentifier)!)
    }
}
