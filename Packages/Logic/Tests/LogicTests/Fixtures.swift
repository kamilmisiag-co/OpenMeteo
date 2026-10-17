//
//  Fixtures.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import Utils

enum Fixtures {
    static let lisbon = City(
        id: 2_267_057, name: "Lisbon", region: "Lisbon", country: "Portugal", countryCode: "PT",
        latitude: 38.7167, longitude: -9.1333, timeZoneIdentifier: "Europe/Lisbon"
    )
    static let bergen = City(
        id: 3_161_732, name: "Bergen", region: "Vestland", country: "Norway", countryCode: "NO",
        latitude: 60.3913, longitude: 5.3221, timeZoneIdentifier: "Europe/Oslo"
    )
    static let zakopane = City(
        id: 3_080_866, name: "Zakopane", region: "Lesser Poland", country: "Poland", countryCode: "PL",
        latitude: 49.2992, longitude: 19.9496, timeZoneIdentifier: "Europe/Warsaw"
    )
    static let auckland = City(
        id: 2_193_733, name: "Auckland", region: "Auckland", country: "New Zealand", countryCode: "NZ",
        latitude: -36.8485, longitude: 174.7633, timeZoneIdentifier: "Pacific/Auckland"
    )
    static let lisboa = City(
        id: lisbon.id, name: "Lisboa", region: nil, country: "Portugal", countryCode: "PT",
        latitude: 38.72, longitude: -9.14, timeZoneIdentifier: "Europe/Lisbon"
    )
    static let noTimeZone = City(
        id: 1, name: "Nowhere", region: nil, country: "Atlantis", countryCode: nil,
        latitude: 0, longitude: 0, timeZoneIdentifier: nil
    )

    static let referenceNow = date(2026, 10, 17, hour: 9, minute: 30, in: "Europe/Lisbon")

    static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0, in timeZoneIdentifier: String) -> Date {
        let timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return Calendar.gregorian(timeZone: timeZone).date(from: components) ?? .distantPast
    }

    static func day(
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

    static func week(startingOn start: Date, in timeZoneIdentifier: String, count: Int = 7) -> [DailyWeather] {
        let calendar = Calendar.gregorian(timeZone: TimeZone(identifier: timeZoneIdentifier) ?? .gmt)
        let first = calendar.startOfDay(for: start)
        return (0..<count).map { offset in
            day(on: calendar.date(byAdding: .day, value: offset, to: first) ?? first)
        }
    }

    static func lisbonDays(from day: Int, count: Int) -> [DailyWeather] {
        week(startingOn: date(2026, 10, day, in: "Europe/Lisbon"), in: "Europe/Lisbon", count: count)
    }
}
