//
//  Fixtures.swift
//  StorageTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Storage

enum Fixtures {
    static let lisbon = City(
        id: 2_267_057, name: "Lisbon", region: "Lisbon", country: "Portugal", countryCode: "PT",
        latitude: 38.71667, longitude: -9.13333, timeZoneIdentifier: "Europe/Lisbon"
    )
    static let bergen = City(
        id: 3_161_732, name: "Bergen", region: "Vestland", country: "Norway", countryCode: "NO",
        latitude: 60.3913, longitude: 5.3221, timeZoneIdentifier: "Europe/Oslo"
    )
    static let zakopane = City(
        id: 3_080_866, name: "Zakopane", region: "Lesser Poland", country: "Poland", countryCode: "PL",
        latitude: 49.2992, longitude: 19.9496, timeZoneIdentifier: "Europe/Warsaw"
    )
    static let referenceNow = Date(timeIntervalSinceReferenceDate: 813_920_400.123_456)
    static let standardFileNames = SafeFileNameEncoder(
        allowedCharacters: StorageStandard.allowedKeyCharacters,
        fileExtension: StorageStandard.fileExtension
    )

    static func day(offset: Int, snowDepth: Double?) -> DailyWeather {
        DailyWeather(
            date: referenceNow.addingTimeInterval(Double(offset) * 86_400),
            condition: .partlyCloudy,
            highCelsius: 21.5,
            lowCelsius: 14.25,
            precipitationProbability: 0.35,
            windSpeedKmh: 18.4,
            windGustsKmh: 31.7,
            snowfallCm: 0,
            snowDepthCm: snowDepth
        )
    }

    static func snapshot(for city: City, dayCount: Int = 7, fetchedAt: Date = referenceNow) -> WeatherSnapshot {
        WeatherSnapshot(
            city: city,
            days: (0..<dayCount).map { day(offset: $0, snowDepth: $0.isMultiple(of: 2) ? nil : Double($0) * 1.5) },
            fetchedAt: fetchedAt
        )
    }
}
