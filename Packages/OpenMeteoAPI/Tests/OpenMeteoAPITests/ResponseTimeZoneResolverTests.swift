//
//  ResponseTimeZoneResolverTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import OpenMeteoAPI
import Testing

@Suite("Response time zone resolver")
struct ResponseTimeZoneResolverTests {
    @Test(
        "Each forecast fixture resolves to the IANA zone it names",
        arguments: [
            (Fixtures.File.forecastZakopane, "Europe/Warsaw"),
            (.forecastZakopaneAuto, "Europe/Warsaw"),
            (.forecastNewYork, "America/New_York"),
            (.forecastAuckland, "Pacific/Auckland"),
            (.forecastAucklandDefaultGMT, "GMT"),
            (.forecastLongyearbyen, "Arctic/Longyearbyen"),
            (.forecastMunichWithNulls, "Europe/Berlin"),
        ]
    )
    func fixtureZones(file: Fixtures.File, identifier: String) throws {
        let expected = try #require(TimeZone(identifier: identifier))
        let response = try Fixtures.decode(ForecastResponseDTO.self, from: file)
        #expect(Self.resolver(fallback: .gmt).timeZone(of: response) == expected)
    }

    @Test("A valid IANA zone wins over the injected fallback")
    func validZoneWins() throws {
        let warsaw = try #require(TimeZone(identifier: "Europe/Warsaw"))
        let fallback = try #require(TimeZone(identifier: "Pacific/Auckland"))
        let response = try Self.response(timezone: "Europe/Warsaw", utcOffsetSeconds: 18_000)
        #expect(Self.resolver(fallback: fallback).timeZone(of: response) == warsaw)
    }

    @Test("An unknown zone ignores the response's fixed UTC offset and uses the injected fallback", arguments: [18_000, -14_400, 46_800, 0])
    func unknownZoneIgnoresOffset(offset: Int) throws {
        let fallback = try #require(TimeZone(identifier: "Pacific/Auckland"))
        let response = try Self.response(timezone: "Mars/Olympus", utcOffsetSeconds: offset)
        #expect(Self.resolver(fallback: fallback).timeZone(of: response) == fallback)
    }

    @Test(
        "An unknown zone without a UTC offset uses the injected fallback",
        arguments: [("Pacific/Auckland", "Mars/Olympus"), ("America/New_York", "Mars/Olympus"), ("Pacific/Auckland", ""), ("America/New_York", "auto")]
    )
    func unknownZoneUsesFallback(fallbackIdentifier: String, timezone: String) throws {
        let fallback = try #require(TimeZone(identifier: fallbackIdentifier))
        let response = try Self.response(timezone: timezone)
        #expect(Self.resolver(fallback: fallback).timeZone(of: response) == fallback)
    }

    private static func resolver(fallback: TimeZone) -> ResponseTimeZoneResolver {
        ResponseTimeZoneResolver(fallbackTimeZone: fallback)
    }

    private static func response(timezone: String, utcOffsetSeconds: Int? = nil) throws -> ForecastResponseDTO {
        let offset = utcOffsetSeconds.map { #", "utc_offset_seconds": \#($0)"# } ?? ""
        let daily = ForecastDailyField.allCases.map { #""\#($0.rawValue)": []"# }.joined(separator: ", ")
        let hourly = ForecastHourlyField.allCases.map { #""\#($0.rawValue)": []"# }.joined(separator: ", ")
        return try Fixtures.decode(
            ForecastResponseDTO.self,
            json: #"{"timezone": "\#(timezone)"\#(offset), "daily": {\#(daily)}, "hourly": {\#(hourly)}}"#
        )
    }
}
