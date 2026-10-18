//
//  PrefixedCityKeyTests.swift
//  StorageTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import Storage
import Testing

@Suite("Prefixed city key")
struct PrefixedCityKeyTests {
    @Test("The key is the prefix followed by the city id", arguments: [
        ("weather-", Fixtures.lisbon, "weather-2267057"),
        ("weather-", Fixtures.bergen, "weather-3161732"),
        ("forecast_", Fixtures.zakopane, "forecast_3080866"),
    ])
    func prefixThenID(prefix: String, city: City, expected: String) {
        #expect(PrefixedCityKey(prefix: prefix).key(for: city) == expected)
    }

    @Test("An empty prefix gives the bare city id")
    func emptyPrefix() {
        #expect(PrefixedCityKey(prefix: "").key(for: Fixtures.lisbon) == "2267057")
        #expect(PrefixedCityKey(prefix: "").key(for: Fixtures.bergen) == "3161732")
    }

    @Test("Zero and negative ids are written in plain decimal", arguments: [
        (0, "weather-0"),
        (-42, "weather--42"),
    ])
    func edgeIDs(id: Int, expected: String) {
        #expect(PrefixedCityKey(prefix: "weather-").key(for: Self.city(id: id, name: "Edge")) == expected)
    }

    @Test("Only the id decides the key, so a city with updated details keeps it")
    func idOnly() {
        let keys = PrefixedCityKey(prefix: "weather-")
        #expect(keys.key(for: Self.city(id: Fixtures.lisbon.id, name: "Lisboa")) == keys.key(for: Fixtures.lisbon))
    }

    private static func city(id: Int, name: String) -> City {
        City(
            id: id, name: name, region: nil, country: "Portugal", countryCode: nil,
            latitude: 38.7, longitude: -9.1, timeZoneIdentifier: nil
        )
    }
}
