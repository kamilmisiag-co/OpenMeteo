//
//  ForecastResponseDecodingTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import OpenMeteoAPI
import Testing

@Suite("Forecast response decoding")
struct ForecastResponseDecodingTests {
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

    @Test("A daily block missing a requested variable fails to decode", arguments: [ForecastDailyField.temperatureMax])
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

    @Test("A forecast without its daily block fails to decode", arguments: [["daily"]])
    func missingBlocks(blocks: [String]) throws {
        let stripped = try Self.zakopane(removingBlocks: blocks)
        let error = #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ForecastResponseDTO.self, from: stripped)
        }
        #expect(Self.missingKey(of: error).map(blocks.contains) == true)
    }

    @Test("Every daily and hourly field except time is requested")
    func requestedFields() {
        #expect(ForecastDailyField.allCases.filter { !$0.isRequested } == [.time])
        #expect(ForecastHourlyField.allCases.filter { !$0.isRequested } == [.time])
        #expect(ForecastDailyField.allCases.filter(\.isRequested).count == ForecastDailyField.allCases.count - 1)
        #expect(ForecastHourlyField.allCases.filter(\.isRequested) == [.snowDepth])
        #expect(ForecastDailyField.requestedNames == ForecastDailyField.allCases.filter(\.isRequested).map(\.rawValue))
        #expect(ForecastHourlyField.requestedNames == ["snow_depth"])
    }

    @Test("A daily block without time fails to decode", arguments: ["daily"])
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
