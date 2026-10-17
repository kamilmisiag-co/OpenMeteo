//
//  ResponseDecodingTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import OpenMeteoAPI
import Testing

@Suite("Response decoding")
struct ResponseDecodingTests {
    @Test(
        "Every geocoding fixture decodes all of its results",
        arguments: [
            (Fixtures.File.geocodingLisbon, 10),
            (.geocodingSaoPaulo, 10),
            (.geocodingMissingCountry, 3),
            (.geocodingNoMatches, 0),
        ]
    )
    func geocodingResultCounts(file: Fixtures.File, count: Int) throws {
        let response = try Fixtures.decode(GeocodingResponseDTO.self, from: file)
        #expect(response.results.count == count)
    }

    @Test("A geocoding response without a results key decodes to an empty list")
    func noMatches() throws {
        let response = try Fixtures.decode(GeocodingResponseDTO.self, from: .geocodingNoMatches)
        #expect(response.results.isEmpty)
    }

    @Test("A geocoding result without a country decodes with a nil country")
    func missingCountry() throws {
        let results = try Fixtures.decode(GeocodingResponseDTO.self, from: .geocodingMissingCountry).results
        let sanJuan = try #require(results.first)
        #expect(results.map(\.id) == [4_568_127, 5_391_811, 2_451_778])
        #expect(results.map(\.country) == [nil, "United States", "Mali"])
        #expect(sanJuan.name == "San Juan")
        #expect(sanJuan.countryCode == "PR")
        #expect(sanJuan.admin1 == "San Juan")
        #expect(sanJuan.timezone == "America/Puerto_Rico")
        #expect(sanJuan.latitude == 18.46633)
        #expect(sanJuan.longitude == -66.10572)
    }

    @Test("Every São Paulo result decodes in the API's order, look-alike duplicates included")
    func saoPaulo() throws {
        let results = try Fixtures.decode(GeocodingResponseDTO.self, from: .geocodingSaoPaulo).results
        #expect(results.map(\.id) == [
            3_448_439, 3_462_944, 3_401_050, 3_468_689, 13_645_899, 2_263_259, 2_410_768, 2_734_380, 2_734_381, 3_388_241,
        ])
        #expect(results.map(\.name) == [
            "São Paulo", "Frei Paulo", "Diamante", "Caatiba", "São Paulo", "São Paulo", "São Paulo", "São Paulo", "São Paulo", "São Paulo",
        ])
        #expect(results.map(\.countryCode) == ["BR", "BR", "BR", "BR", "CV", "PT", "ST", "PT", "PT", "BR"])
        #expect(results.map(\.country) == [
            "Brazil", "Brazil", "Brazil", "Brazil", "Cabo Verde", "Portugal", "São Tomé and Príncipe", "Portugal", "Portugal", "Brazil",
        ])
        #expect(results.map(\.admin1) == [
            "São Paulo", "Sergipe", "Paraíba", "Estado de Bahia", "Sal", "Coimbra District", "São Tomé Island",
            "Coimbra District", "Coimbra District", "Alagoas",
        ])
        let first = try #require(results.first)
        #expect(first.latitude == -23.5475)
        #expect(first.longitude == -46.63611)
        #expect(first.timezone == "America/Sao_Paulo")
    }

    @Test("Integer weather codes and probabilities decode from the Zakopane forecast")
    func integerValues() throws {
        let response = try Fixtures.decode(ForecastResponseDTO.self, from: .forecastZakopane)
        let daily = response.daily
        let hourly = response.hourly
        #expect(response.timezone == "Europe/Warsaw")
        #expect(daily.time == ["2026-10-17", "2026-10-18", "2026-10-19", "2026-10-20", "2026-10-21", "2026-10-22", "2026-10-23"])
        #expect(daily.weatherCode == [0, 3, 51, 51, 51, 55, 53])
        #expect(daily.precipitationProbabilityMax == [0, 4, 7, 20, 43, 67, 44])
        #expect(daily.temperatureMax == [13.1, 12.0, 5.2, 9.6, 14.4, 11.6, 8.8])
        #expect(daily.temperatureMin == [2.5, 2.0, -0.3, 2.7, 4.1, 7.6, 4.6])
        #expect(daily.windSpeedMax == [7.6, 7.9, 9.4, 9.5, 9.6, 6.0, 8.1])
        #expect(daily.windGustsMax == [15.1, 15.8, 18.0, 20.2, 21.6, 16.6, 19.4])
        #expect(daily.snowfallSum == [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
        #expect(hourly.time.count == 168)
        #expect(hourly.time.first == "2026-10-17T00:00")
        #expect(hourly.time.last == "2026-10-23T23:00")
        #expect(hourly.snowDepth.count == 168)
    }

    @Test("Integer JSON numbers decode into every floating-point daily variable")
    func integerFloatingPointValues() throws {
        let response = try Fixtures.decode(ForecastResponseDTO.self, json: #"""
        {
          "timezone": "GMT",
          "daily": {
            "time": ["2026-10-17"], "weather_code": [3], "temperature_2m_max": [13], "temperature_2m_min": [-2],
            "precipitation_probability_max": [100], "wind_speed_10m_max": [8], "wind_gusts_10m_max": [15], "snowfall_sum": [0]
          },
          "hourly": {"time": ["2026-10-17T00:00"], "snow_depth": [1]}
        }
        """#)
        let daily = response.daily
        #expect(daily.weatherCode == [3])
        #expect(daily.temperatureMax == [13.0])
        #expect(daily.temperatureMin == [-2.0])
        #expect(daily.precipitationProbabilityMax == [100.0])
        #expect(daily.windSpeedMax == [8.0])
        #expect(daily.windGustsMax == [15.0])
        #expect(daily.snowfallSum == [0.0])
        #expect(response.hourly.snowDepth == [1.0])
    }

    @Test("Null daily and hourly values from the Munich icon_d2 forecast decode as nil")
    func nullValues() throws {
        let response = try Fixtures.decode(ForecastResponseDTO.self, from: .forecastMunichWithNulls)
        let daily = response.daily
        let hourly = response.hourly
        #expect(response.timezone == "Europe/Berlin")
        #expect(daily.weatherCode == [80, 80, nil, nil, nil, nil, nil])
        #expect(daily.precipitationProbabilityMax == [30, 60, nil, nil, nil, nil, nil])
        #expect(daily.snowfallSum == [0.0, 0.0, nil, nil, nil, nil, nil])
        #expect(hourly.snowDepth.count == 168)
        #expect(hourly.snowDepth.count(where: { $0 == nil }) == 108)
    }

    @Test("A daily block missing any requested variable fails to decode", arguments: ForecastDailyField.allCases.filter(\.isRequested))
    func missingDailyVariable(field: ForecastDailyField) throws {
        let stripped = try Self.zakopane(removing: field.rawValue, from: "daily")
        let error = #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ForecastResponseDTO.self, from: stripped)
        }
        #expect(Self.missingKey(of: error) == field.rawValue)
    }

    @Test("An hourly block missing any requested variable fails to decode", arguments: ForecastHourlyField.allCases.filter(\.isRequested))
    func missingHourlyVariable(field: ForecastHourlyField) throws {
        let stripped = try Self.zakopane(removing: field.rawValue, from: "hourly")
        let error = #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ForecastResponseDTO.self, from: stripped)
        }
        #expect(Self.missingKey(of: error) == field.rawValue)
    }

    @Test("A decoder that converts snake case fails loudly instead of decoding empty arrays")
    func convertingDecoderFails() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = try Fixtures.data(.forecastZakopane)
        #expect(throws: DecodingError.self) {
            try decoder.decode(ForecastResponseDTO.self, from: data)
        }
    }

    @Test("A geocoding response whose every result is malformed fails to decode instead of reading as no matches")
    func allResultsMalformed() {
        #expect(throws: DecodingError.self) {
            try Fixtures.decode(GeocodingResponseDTO.self, json: #"""
            {"results": [{"name": "No identifier", "latitude": 1.0, "longitude": 2.0}, {"id": "x", "name": "Bad", "latitude": 3.0, "longitude": 4.0}]}
            """#)
        }
    }

    @Test("A forecast without its daily or hourly block fails to decode", arguments: [["daily"], ["hourly"], ["daily", "hourly"]])
    func missingBlocks(blocks: [String]) throws {
        let stripped = try Self.zakopane(removingBlocks: blocks)
        let error = #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ForecastResponseDTO.self, from: stripped)
        }
        #expect(Self.missingKey(of: error).map(blocks.contains) == true)
    }

    @Test("A forecast with only a time zone fails to decode")
    func onlyTimeZone() {
        #expect(throws: DecodingError.self) {
            try Fixtures.decode(ForecastResponseDTO.self, json: #"{"timezone": "GMT", "utc_offset_seconds": 0}"#)
        }
    }

    @Test(
        "Every successful forecast fixture has daily arrays as long as time and 24 hourly entries per day",
        arguments: [
            Fixtures.File.forecastZakopane, .forecastZakopaneSixteenDays, .forecastAuckland, .forecastAucklandDefaultGMT,
            .forecastNewYork, .forecastLongyearbyen, .forecastMunichWithNulls,
        ]
    )
    func forecastShapes(file: Fixtures.File) throws {
        let response = try Fixtures.decode(ForecastResponseDTO.self, from: file)
        let daily = response.daily
        let hourly = response.hourly
        let dayCount = daily.time.count
        #expect(daily.weatherCode.count == dayCount)
        #expect(daily.temperatureMax.count == dayCount)
        #expect(daily.temperatureMin.count == dayCount)
        #expect(daily.precipitationProbabilityMax.count == dayCount)
        #expect(daily.windSpeedMax.count == dayCount)
        #expect(daily.windGustsMax.count == dayCount)
        #expect(daily.snowfallSum.count == dayCount)
        #expect(hourly.time.count == 24 * dayCount)
        #expect(hourly.snowDepth.count == hourly.time.count)
    }

    @Test(
        "The daily and hourly field names are exactly the keys of every successful forecast fixture",
        arguments: [
            Fixtures.File.forecastZakopane, .forecastZakopaneAuto, .forecastZakopaneSixteenDays, .forecastAuckland,
            .forecastAucklandDefaultGMT, .forecastNewYork, .forecastLongyearbyen, .forecastMunichWithNulls,
        ]
    )
    func fieldNamesMatchFixtureKeys(file: Fixtures.File) throws {
        let object = try #require(try JSONSerialization.jsonObject(with: Fixtures.data(file)) as? [String: Any])
        let daily = try #require(object["daily"] as? [String: Any])
        let hourly = try #require(object["hourly"] as? [String: Any])
        #expect(Set(daily.keys) == Set(ForecastDailyField.allCases.map(\.rawValue)))
        #expect(Set(hourly.keys) == Set(ForecastHourlyField.allCases.map(\.rawValue)))
    }

    @Test("Every daily and hourly field except time is requested")
    func requestedFields() {
        #expect(ForecastDailyField.allCases.filter { !$0.isRequested } == [.time])
        #expect(ForecastHourlyField.allCases.filter { !$0.isRequested } == [.time])
        #expect(ForecastDailyField.allCases.filter(\.isRequested).count == ForecastDailyField.allCases.count - 1)
        #expect(ForecastHourlyField.allCases.filter(\.isRequested) == [.snowDepth])
    }

    @Test("A daily or hourly block without time fails to decode", arguments: ["daily", "hourly"])
    func missingTime(block: String) throws {
        let stripped = try Self.zakopane(removing: "time", from: block)
        let error = #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ForecastResponseDTO.self, from: stripped)
        }
        #expect(Self.missingKey(of: error) == "time")
    }

    @Test(
        "Error bodies do not decode as a forecast",
        arguments: [Fixtures.File.forecastErrorBadDailyVariable, .forecastErrorOverloaded, .geocodingErrorCountZero]
    )
    func errorBodies(file: Fixtures.File) {
        #expect(throws: DecodingError.self) {
            try Fixtures.decode(ForecastResponseDTO.self, from: file)
        }
    }

    @Test("A result missing a required field is dropped and the other results are kept")
    func lossyResults() throws {
        let response = try Fixtures.decode(GeocodingResponseDTO.self, json: #"""
        {"results": [
            {"id": 1, "name": "Alpha", "latitude": 1.0, "longitude": 2.0},
            {"name": "No identifier", "latitude": 3.0, "longitude": 4.0},
            {"id": 3, "name": "Gamma", "latitude": 5.0, "longitude": 6.0}
        ]}
        """#)
        #expect(response.results.map(\.id) == [1, 3])
    }

    private static func zakopaneObject() throws -> [String: Any] {
        try #require(try JSONSerialization.jsonObject(with: Fixtures.data(.forecastZakopane)) as? [String: Any])
    }

    private static func zakopane(removing key: String, from block: String) throws -> Data {
        var object = try zakopaneObject()
        var nested = try #require(object[block] as? [String: Any])
        try #require(nested[key] != nil)
        nested[key] = nil
        object[block] = nested
        return try JSONSerialization.data(withJSONObject: object)
    }

    private static func zakopane(removingBlocks blocks: [String]) throws -> Data {
        var object = try zakopaneObject()
        for block in blocks {
            try #require(object[block] != nil)
            object[block] = nil
        }
        return try JSONSerialization.data(withJSONObject: object)
    }

    private static func missingKey(of error: DecodingError?) -> String? {
        guard case .keyNotFound(let key, _)? = error else { return nil }
        return key.stringValue
    }
}
