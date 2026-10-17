//
//  ForecastEndpointTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Networking
import OpenMeteoAPI
import Synchronization
import Testing

@Suite("Forecast endpoint")
struct ForecastEndpointTests {
    private final class RecordingResponseDecoder<Sentinel: Sendable>: ResponseDecoding {
        struct Call: Hashable, Sendable {
            let type: ObjectIdentifier
            let data: Data
        }

        private let sentinel: Sentinel
        private let received = Mutex<[Call]>([])

        init(sentinel: Sentinel) {
            self.sentinel = sentinel
        }

        var calls: [Call] {
            received.withLock { $0 }
        }

        func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
            received.withLock { $0.append(Call(type: ObjectIdentifier(type), data: data)) }
            return try #require(sentinel as? Value)
        }
    }

    private struct DecoderFailure: Error, Equatable {}

    private struct FailingResponseDecoder: ResponseDecoding {
        func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
            throw DecoderFailure()
        }
    }

    @Test("Fetches with GET on the v1/forecast path without headers or a body")
    func methodAndPath() {
        let endpoint = ForecastEndpoint(latitude: 49.2992, longitude: 19.9496, timeZoneIdentifier: "Europe/Warsaw", dayCount: 8)
        #expect(endpoint.method == .get)
        #expect(endpoint.path == "v1/forecast")
        #expect(endpoint.headers.isEmpty)
        #expect(endpoint.body == nil)
    }

    @Test("Keeps the coordinates, time zone and day count it was built with")
    func storedValues() {
        let endpoint = ForecastEndpoint(latitude: 49.2992, longitude: 19.9496, timeZoneIdentifier: "Europe/Warsaw", dayCount: 8)
        #expect(endpoint.latitude == 49.2992)
        #expect(endpoint.longitude == 19.9496)
        #expect(endpoint.timeZoneIdentifier == "Europe/Warsaw")
        #expect(endpoint.dayCount == 8)
    }

    @Test("Sends coordinates, the daily variables, hourly snow depth, the time zone and the day count in that order")
    func queryItems() {
        let endpoint = ForecastEndpoint(latitude: 49.2992, longitude: 19.9496, timeZoneIdentifier: "Europe/Warsaw", dayCount: 8)
        #expect(endpoint.queryItems == [
            URLQueryItem(name: "latitude", value: "49.2992"),
            URLQueryItem(name: "longitude", value: "19.9496"),
            URLQueryItem(
                name: "daily",
                value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,wind_gusts_10m_max,snowfall_sum"
            ),
            URLQueryItem(name: "hourly", value: "snow_depth"),
            URLQueryItem(name: "timezone", value: "Europe/Warsaw"),
            URLQueryItem(name: "forecast_days", value: "8"),
        ])
    }

    @Test(
        "Sends the day count and time zone exactly as given, leaving clamping and fallbacks to the request factory",
        arguments: [(0, ""), (-3, "  "), (17, "Mars/Olympus"), (Int.max, "auto"), (Int.min, "UTC")]
    )
    func passesValuesThrough(dayCount: Int, timeZoneIdentifier: String) {
        let endpoint = ForecastEndpoint(latitude: 0, longitude: 0, timeZoneIdentifier: timeZoneIdentifier, dayCount: dayCount)
        #expect(endpoint.dayCount == dayCount)
        #expect(endpoint.timeZoneIdentifier == timeZoneIdentifier)
        #expect(endpoint.queryItems.first { $0.name == "forecast_days" }?.value == String(dayCount))
        #expect(endpoint.queryItems.first { $0.name == "timezone" }?.value == timeZoneIdentifier)
    }

    @Test("Writes coordinates the way Swift prints a Double", arguments: [
        (38.71667, "38.71667"),
        (-9.13333, "-9.13333"),
        (0, "0.0"),
        (-36.84853, "-36.84853"),
        (174.76349, "174.76349"),
    ])
    func coordinateFormatting(coordinate: Double, expected: String) {
        let endpoint = ForecastEndpoint(latitude: coordinate, longitude: coordinate, timeZoneIdentifier: "auto", dayCount: 7)
        let values = endpoint.queryItems.filter { ["latitude", "longitude"].contains($0.name) }.map(\.value)
        #expect(values == [expected, expected])
    }

    @Test("Asks for every daily and hourly field the response decodes except time, in declaration order")
    func requestedFieldsComeFromTheDecodedFields() {
        let endpoint = ForecastEndpoint(latitude: 49.2992, longitude: 19.9496, timeZoneIdentifier: "Europe/Warsaw", dayCount: 7)
        #expect(requestedVariables(named: "daily", in: endpoint) == ForecastDailyField.allCases.filter(\.isRequested).map(\.rawValue))
        #expect(requestedVariables(named: "hourly", in: endpoint) == ForecastHourlyField.allCases.filter(\.isRequested).map(\.rawValue))
        #expect(ForecastDailyField.allCases.filter { !$0.isRequested } == [.time])
        #expect(ForecastHourlyField.allCases.filter { !$0.isRequested } == [.time])
    }

    @Test(
        "Builds the forecast URL on the forecast host with commas and slashes left as they are",
        arguments: [
            (
                ForecastEndpoint(latitude: 49.2992, longitude: 19.9496, timeZoneIdentifier: "Europe/Warsaw", dayCount: 8),
                "https://api.open-meteo.com/v1/forecast?latitude=49.2992&longitude=19.9496&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,wind_gusts_10m_max,snowfall_sum&hourly=snow_depth&timezone=Europe/Warsaw&forecast_days=8"
            ),
            (
                ForecastEndpoint(latitude: 38.71667, longitude: -9.13333, timeZoneIdentifier: "auto", dayCount: 16),
                "https://api.open-meteo.com/v1/forecast?latitude=38.71667&longitude=-9.13333&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,wind_gusts_10m_max,snowfall_sum&hourly=snow_depth&timezone=auto&forecast_days=16"
            ),
            (
                ForecastEndpoint(latitude: 40.71427, longitude: -74.00597, timeZoneIdentifier: "America/New_York", dayCount: 1),
                "https://api.open-meteo.com/v1/forecast?latitude=40.71427&longitude=-74.00597&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,wind_gusts_10m_max,snowfall_sum&hourly=snow_depth&timezone=America/New_York&forecast_days=1"
            ),
        ]
    )
    func url(endpoint: ForecastEndpoint, expected: String) throws {
        let request = try builtRequest(for: endpoint)
        #expect(request.url?.absoluteString == expected)
    }

    @Test("Percent-encodes a plus sign in the time zone so the server doesn't read it as a space")
    func plusInTimeZone() throws {
        let request = try builtRequest(for: ForecastEndpoint(latitude: 0, longitude: 0, timeZoneIdentifier: "Etc/GMT+2", dayCount: 7))
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(url.absoluteString.hasSuffix("&timezone=Etc/GMT%2B2&forecast_days=7"))
        #expect(components.queryItems?.first { $0.name == "timezone" }?.value == "Etc/GMT+2")
    }

    @Test("Builds a GET request with a 15 second timeout, no headers and no body")
    func requestShape() throws {
        let request = try builtRequest(for: ForecastEndpoint(latitude: 38.71667, longitude: -9.13333, timeZoneIdentifier: "auto", dayCount: 8))
        #expect(request.httpMethod == "GET")
        #expect(request.timeoutInterval == 15)
        #expect((request.allHTTPHeaderFields ?? [:]).isEmpty)
        #expect(request.httpBody == nil)
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

    @Test("Decoding hands the response body to the injected decoder and returns exactly what it decodes")
    func decodesThroughInjectedDecoder() throws {
        let sentinel = try Fixtures.decode(ForecastResponseDTO.self, from: .forecastAuckland)
        let response = try Fixtures.response(.forecastZakopane)
        let decoder = RecordingResponseDecoder(sentinel: sentinel)
        let endpoint = ForecastEndpoint(latitude: 49.2992, longitude: 19.9496, timeZoneIdentifier: "Europe/Warsaw", dayCount: 7)
        let bodyDecodedDirectly = try Fixtures.decode(ForecastResponseDTO.self, from: .forecastZakopane)

        let decoded = try endpoint.decode(response, using: decoder)

        #expect(decoded == sentinel)
        #expect(decoded != bodyDecodedDirectly)
        #expect(decoder.calls == [.init(type: ObjectIdentifier(ForecastResponseDTO.self), data: response.body)])
    }

    @Test("A failure from the injected decoder reaches the caller instead of falling back to another decoder")
    func injectedDecoderFailure() throws {
        let endpoint = ForecastEndpoint(latitude: 49.2992, longitude: 19.9496, timeZoneIdentifier: "Europe/Warsaw", dayCount: 7)
        let response = try Fixtures.response(.forecastZakopane)
        #expect(throws: DecoderFailure()) {
            try endpoint.decode(response, using: FailingResponseDecoder())
        }
    }

    private func requestedVariables(named name: String, in endpoint: ForecastEndpoint) -> [String] {
        let value = endpoint.queryItems.first { $0.name == name }?.value ?? ""
        return value.split(separator: ",").map(String.init)
    }

    private func builtRequest(for endpoint: ForecastEndpoint) throws -> URLRequest {
        try Fixtures.requestBuilder(host: OpenMeteoStandard.forecastHost).makeRequest(for: endpoint)
    }
}
