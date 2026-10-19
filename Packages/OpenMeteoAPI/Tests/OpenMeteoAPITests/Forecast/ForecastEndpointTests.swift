//
//  ForecastEndpointTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Networking
import OpenMeteoAPI
import Testing

@Suite("Forecast endpoint")
struct ForecastEndpointTests {
    @Test(
        "Builds the forecast URL on the forecast host with commas and slashes left as they are",
        arguments: [
            (
                ForecastEndpoint(latitude: 49.2992, longitude: 19.9496, timeZoneIdentifier: "Europe/Warsaw", dayCount: 8),
                "https://api.open-meteo.com/v1/forecast?latitude=49.2992&longitude=19.9496&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,wind_gusts_10m_max,snowfall_sum&hourly=snow_depth&timezone=Europe/Warsaw&forecast_days=8"
            ),
        ]
    )
    func url(endpoint: ForecastEndpoint, expected: String) throws {
        let request = try builtRequest(for: endpoint)
        #expect(request.url?.absoluteString == expected)
    }

    @Test(
        "Asks for exactly the daily and hourly variables every recorded response carries",
        arguments: Fixtures.File.allCases.filter { $0.rawValue.hasPrefix("forecast_") && !$0.rawValue.hasPrefix("forecast_error_") }
    )
    func variablesMatchRecordedResponse(file: Fixtures.File) throws {
        let object = try #require(JSONSerialization.jsonObject(with: Fixtures.data(file)) as? [String: Any])
        let daily = try #require(object["daily"] as? [String: Any])
        let hourly = try #require(object["hourly"] as? [String: Any])
        let endpoint = ForecastEndpoint(latitude: 49.2992, longitude: 19.9496, timeZoneIdentifier: "Europe/Warsaw", dayCount: 7)
        #expect(Set(daily.keys).subtracting([ForecastDailyField.time.rawValue]) == Set(requestedVariables(named: "daily", in: endpoint)))
        #expect(Set(hourly.keys).subtracting([ForecastHourlyField.time.rawValue]) == Set(requestedVariables(named: "hourly", in: endpoint)))
        #expect(Set(daily.keys) == Set(ForecastDailyField.allCases.map(\.stringValue)))
        #expect(Set(hourly.keys) == Set(ForecastHourlyField.allCases.map(\.stringValue)))
    }

    private func requestedVariables(named name: String, in endpoint: ForecastEndpoint) -> [String] {
        let value = endpoint.queryItems.first { $0.name == name }?.value ?? ""
        return value.split(separator: ",").map(String.init)
    }

    private func builtRequest(for endpoint: ForecastEndpoint) throws -> URLRequest {
        try Fixtures.requestBuilder(baseURL: OpenMeteoStandard.forecastBaseURL).makeRequest(for: endpoint)
    }
}
