//
//  PreviewCities.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

#if DEBUG
import Logic

nonisolated enum PreviewCities {
    static let lisbon = City(
        id: 2_267_057, name: "Lisbon", region: "Lisbon", country: "Portugal", countryCode: "PT",
        latitude: 38.7167, longitude: -9.1333, timeZoneIdentifier: "Europe/Lisbon"
    )
    static let lisburn = City(
        id: 2_644_411, name: "Lisburn", region: "Northern Ireland", country: "United Kingdom", countryCode: "GB",
        latitude: 54.5167, longitude: -6.0333, timeZoneIdentifier: "Europe/London"
    )
    static let lisieux = City(
        id: 2_998_150, name: "Lisieux", region: "Normandy", country: "France", countryCode: "FR",
        latitude: 49.1466, longitude: 0.2293, timeZoneIdentifier: "Europe/Paris"
    )
    static let lisbonOhio = City(
        id: 5_160_315, name: "Lisbon", region: "Ohio", country: "United States", countryCode: "US",
        latitude: 40.7720, longitude: -80.7681, timeZoneIdentifier: "America/New_York"
    )
    static let lismore = City(
        id: 2_160_063, name: "Lismore", region: "New South Wales", country: "Australia", countryCode: "AU",
        latitude: -28.8167, longitude: 153.2833, timeZoneIdentifier: "Australia/Sydney"
    )
    static let zakopane = City(
        id: 3_080_866, name: "Zakopane", region: "Lesser Poland", country: "Poland", countryCode: "PL",
        latitude: 49.2992, longitude: 19.9496, timeZoneIdentifier: "Europe/Warsaw"
    )
    static let biarritz = City(
        id: 3_032_797, name: "Biarritz", region: "Nouvelle-Aquitaine", country: "France", countryCode: "FR",
        latitude: 43.4832, longitude: -1.5586, timeZoneIdentifier: "Europe/Paris"
    )
    static let bergen = City(
        id: 3_161_732, name: "Bergen", region: "Vestland", country: "Norway", countryCode: "NO",
        latitude: 60.3913, longitude: 5.3221, timeZoneIdentifier: "Europe/Oslo"
    )

    static let all: [City] = [lisbon, lisburn, lisieux, lisbonOhio, lismore, zakopane, biarritz, bergen]
    static let recents: [City] = [lisbon, zakopane, biarritz]
}
#endif
