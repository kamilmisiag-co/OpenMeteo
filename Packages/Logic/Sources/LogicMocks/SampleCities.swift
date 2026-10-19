//
//  SampleCities.swift
//  LogicMocks
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Logic

public enum SampleCities {
    public static let lisbon = City(
        id: 2_267_057, name: "Lisbon", region: "Lisbon", country: "Portugal", countryCode: "PT",
        latitude: 38.7167, longitude: -9.1333, timeZoneIdentifier: "Europe/Lisbon"
    )
    public static let bergen = City(
        id: 3_161_732, name: "Bergen", region: "Vestland", country: "Norway", countryCode: "NO",
        latitude: 60.3913, longitude: 5.3221, timeZoneIdentifier: "Europe/Oslo"
    )
    public static let zakopane = City(
        id: 3_080_866, name: "Zakopane", region: "Lesser Poland", country: "Poland", countryCode: "PL",
        latitude: 49.2992, longitude: 19.9496, timeZoneIdentifier: "Europe/Warsaw"
    )
    public static let noTimeZone = City(
        id: 1, name: "Nowhere", region: nil, country: "Atlantis", countryCode: nil,
        latitude: 0, longitude: 0, timeZoneIdentifier: nil
    )
}
