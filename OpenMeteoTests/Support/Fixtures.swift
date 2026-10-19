//
//  Fixtures.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic

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
}
