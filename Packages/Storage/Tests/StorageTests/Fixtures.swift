//
//  Fixtures.swift
//  StorageTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import LogicMocks
import Storage

enum Fixtures {
    static let referenceNow = Date(timeIntervalSinceReferenceDate: 813_920_400.123_456)
    static let standardFileNames = SafeFileNameEncoder(fileExtension: StorageStandard.fileExtension)

    static func snapshot(for city: City) -> WeatherSnapshot {
        let days = (0..<7).map { offset in
            LogicFixtures.day(
                on: referenceNow.addingTimeInterval(Double(offset) * 86_400),
                condition: .partlyCloudy,
                high: 21.5,
                low: 14.25,
                rain: 0.35,
                wind: 18.4,
                gusts: 31.7,
                snowDepth: offset.isMultiple(of: 2) ? nil : Double(offset) * 1.5
            )
        }
        return WeatherSnapshot(city: city, days: days, fetchedAt: referenceNow)
    }
}
