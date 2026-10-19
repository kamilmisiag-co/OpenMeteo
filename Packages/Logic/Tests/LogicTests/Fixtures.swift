//
//  Fixtures.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import LogicMocks
import Utils

enum Fixtures {
    static let auckland = City(
        id: 2_193_733, name: "Auckland", region: "Auckland", country: "New Zealand", countryCode: "NZ",
        latitude: -36.8485, longitude: 174.7633, timeZoneIdentifier: "Pacific/Auckland"
    )
    static let lisboa = City(
        id: SampleCities.lisbon.id, name: "Lisboa", region: nil, country: "Portugal", countryCode: "PT",
        latitude: 38.72, longitude: -9.14, timeZoneIdentifier: "Europe/Lisbon"
    )
    static let lisbonCalendar = Calendar.gregorian(timeZone: TimeZone(identifier: "Europe/Lisbon")!)
}
