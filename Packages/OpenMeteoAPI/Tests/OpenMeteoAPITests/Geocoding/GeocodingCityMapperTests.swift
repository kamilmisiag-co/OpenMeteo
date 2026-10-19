//
//  GeocodingCityMapperTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import OpenMeteoAPI
import Synchronization
import Testing

@Suite("Geocoding city mapper")
struct GeocodingCityMapperTests {
    private final class RecordingRegionNames: RegionNameProviding {
        private let names: [String: String]
        private let requested = Mutex<[String]>([])

        init(_ names: [String: String] = [:]) {
            self.names = names
        }

        var requestedCodes: [String] {
            requested.withLock { $0 }
        }

        func name(forRegionCode code: String) -> String? {
            requested.withLock { $0.append(code) }
            return names[code]
        }
    }

    @Test("A country name from the API wins and the region name provider is not asked")
    func apiCountryWins() throws {
        let result = try #require(try Fixtures.decode(GeocodingResponseDTO.self, from: .geocodingLisbon).results.first)
        let regionNames = RecordingRegionNames(["PT": "Portugalia"])
        let city = try #require(GeocodingCityMapper(regionNames: regionNames).city(from: result))
        #expect(city.country == "Portugal")
        #expect(regionNames.requestedCodes.isEmpty)
    }

    @Test("Every Lisbon result maps in the API's order")
    func allLisbonResults() throws {
        let results = try Fixtures.decode(GeocodingResponseDTO.self, from: .geocodingLisbon).results
        let mapper = GeocodingCityMapper(regionNames: RecordingRegionNames())
        let cities = try results.map { try #require(mapper.city(from: $0)) }
        #expect(cities == Fixtures.geocodedLisbonCities)
    }

    @Test(
        "A result without a country is named by the injected region name provider from its country code",
        arguments: ["Portoryko"]
    )
    func missingCountry(providedName: String) throws {
        let sanJuan = try #require(try Fixtures.decode(GeocodingResponseDTO.self, from: .geocodingMissingCountry).results.first)
        let regionNames = RecordingRegionNames(["PR": providedName])
        let expected = City(
            id: 4_568_127, name: "San Juan", region: "San Juan", country: providedName, countryCode: "PR",
            latitude: 18.46633, longitude: -66.10572, timeZoneIdentifier: "America/Puerto_Rico"
        )
        let city = try #require(GeocodingCityMapper(regionNames: regionNames).city(from: sanJuan))
        #expect(city == expected)
        #expect(regionNames.requestedCodes == ["PR"])
    }

    @Test("The region name provider is asked once with the trimmed, uppercased country code", arguments: [#" pr\n"#])
    func providerReceivesUppercasedCode(code: String) throws {
        let result = try Self.result(json: #"""
        {"id": 7, "name": "Ponce", "latitude": 18.01108, "longitude": -66.61406, "country_code": "\#(code)"}
        """#)
        let regionNames = RecordingRegionNames(["PR": "Puerto Rico"])
        let city = try #require(GeocodingCityMapper(regionNames: regionNames).city(from: result))
        #expect(regionNames.requestedCodes == ["PR"])
        #expect(city.country == "Puerto Rico")
        #expect(city.countryCode == "PR")
    }

    @Test("A country code the provider does not know becomes the country name, uppercased")
    func unknownCountryCode() throws {
        let result = try Self.result(json: #"{"id": 1, "name": "Nowhere", "latitude": 1.5, "longitude": -2.5, "country_code": "xx"}"#)
        let regionNames = RecordingRegionNames()
        let expected = City(
            id: 1, name: "Nowhere", region: nil, country: "XX", countryCode: "XX",
            latitude: 1.5, longitude: -2.5, timeZoneIdentifier: nil
        )
        let city = try #require(GeocodingCityMapper(regionNames: regionNames).city(from: result))
        #expect(city == expected)
        #expect(regionNames.requestedCodes == ["XX"])
    }

    @Test("A result with neither a country nor a country code gets an empty country without asking the provider")
    func noCountryAtAll() throws {
        let result = try Self.result(json: #"{"id": 2, "name": "Nowhere", "latitude": 0.0, "longitude": 0.0}"#)
        let regionNames = RecordingRegionNames()
        let expected = City(
            id: 2, name: "Nowhere", region: nil, country: "", countryCode: nil,
            latitude: 0, longitude: 0, timeZoneIdentifier: nil
        )
        let city = try #require(GeocodingCityMapper(regionNames: regionNames).city(from: result))
        #expect(city == expected)
        #expect(regionNames.requestedCodes.isEmpty)
    }

    @Test("Empty or whitespace-only text fields count as absent", arguments: [#" \t\n "#])
    func blankFields(blank: String) throws {
        let result = try Self.result(json: #"""
        {
          "id": 3, "name": "Blankville", "latitude": 10.25, "longitude": 20.5,
          "country_code": "\#(blank)", "country": "\#(blank)", "admin1": "\#(blank)", "timezone": "\#(blank)"
        }
        """#)
        let regionNames = RecordingRegionNames()
        let expected = City(
            id: 3, name: "Blankville", region: nil, country: "", countryCode: nil,
            latitude: 10.25, longitude: 20.5, timeZoneIdentifier: nil
        )
        let city = try #require(GeocodingCityMapper(regionNames: regionNames).city(from: result))
        #expect(city == expected)
        #expect(regionNames.requestedCodes.isEmpty)
    }

    @Test("A result whose name is empty or whitespace-only maps to no city", arguments: [#" \t\n "#])
    func blankName(blank: String) throws {
        let result = try Self.result(json: #"""
        {
          "id": 9, "name": "\#(blank)", "latitude": 41.14961, "longitude": -8.61099,
          "country_code": "PT", "country": "Portugal", "admin1": "Porto", "timezone": "Europe/Lisbon"
        }
        """#)
        #expect(GeocodingCityMapper(regionNames: RecordingRegionNames()).city(from: result) == nil)
    }

    @Test(
        "An empty or whitespace-only name from the region name provider falls back to the uppercased country code",
        arguments: [" \t\n "]
    )
    func blankProvidedName(provided: String) throws {
        let result = try Self.result(json: #"{"id": 10, "name": "Ponce", "latitude": 18.01108, "longitude": -66.61406, "country_code": "pr"}"#)
        let regionNames = RecordingRegionNames(["PR": provided])
        let expected = City(
            id: 10, name: "Ponce", region: nil, country: "PR", countryCode: "PR",
            latitude: 18.01108, longitude: -66.61406, timeZoneIdentifier: nil
        )
        let city = try #require(GeocodingCityMapper(regionNames: regionNames).city(from: result))
        #expect(city == expected)
        #expect(regionNames.requestedCodes == ["PR"])
    }

    @Test("Surrounding whitespace is trimmed from the name and every optional text field")
    func trimmedFields() throws {
        let result = try Self.result(json: #"""
        {
          "id": 8, "name": " Porto\t", "latitude": 41.14961, "longitude": -8.61099,
          "country_code": " pt ", "country": "  Portugal\n", "admin1": "\tPorto ", "timezone": " Europe/Lisbon "
        }
        """#)
        let expected = City(
            id: 8, name: "Porto", region: "Porto", country: "Portugal", countryCode: "PT",
            latitude: 41.14961, longitude: -8.61099, timeZoneIdentifier: "Europe/Lisbon"
        )
        let city = try #require(GeocodingCityMapper(regionNames: RecordingRegionNames()).city(from: result))
        #expect(city == expected)
    }

    @Test("A blank country falls back to the injected provider's name for the country code", arguments: ["  "])
    func blankCountry(blank: String) throws {
        let result = try Self.result(json: #"""
        {"id": 4, "name": "Porto", "latitude": 41.14961, "longitude": -8.61099, "country_code": "PT", "country": "\#(blank)"}
        """#)
        let regionNames = RecordingRegionNames(["PT": "Portugalia"])
        let city = try #require(GeocodingCityMapper(regionNames: regionNames).city(from: result))
        #expect(city.country == "Portugalia")
        #expect(city.countryCode == "PT")
        #expect(regionNames.requestedCodes == ["PT"])
    }

    @Test("A blank country code is absent while the API's country name is kept")
    func blankCountryCode() throws {
        let result = try Self.result(json: #"""
        {"id": 5, "name": "Porto", "latitude": 41.14961, "longitude": -8.61099, "country_code": " ", "country": "Portugal"}
        """#)
        let regionNames = RecordingRegionNames()
        let city = try #require(GeocodingCityMapper(regionNames: regionNames).city(from: result))
        #expect(city.countryCode == nil)
        #expect(city.country == "Portugal")
        #expect(regionNames.requestedCodes.isEmpty)
    }

    private static func result(json: String) throws -> GeocodingResultDTO {
        try Fixtures.decode(GeocodingResultDTO.self, json: json)
    }
}
