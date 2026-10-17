//
//  OpenMeteoClientIntegrationTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import Networking
import NetworkingMocks
import OpenMeteoAPI
import Testing
import Utils

@Suite("Open-Meteo client integration")
struct OpenMeteoClientIntegrationTests {
    private static let lisbonSearchURL = "https://geocoding-api.open-meteo.com/v1/search?name=Lisbon&count=10&language=en&format=json"
    private static let saoPauloSearchURL = "https://geocoding-api.open-meteo.com/v1/search?name=S%C3%A3o%20Paulo&count=10&language=en&format=json"
    private static let zakopaneForecastQuery = "https://api.open-meteo.com/v1/forecast?latitude=49.2992&longitude=19.9496"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,wind_gusts_10m_max,snowfall_sum"
        + "&hourly=snow_depth"
    private static let zakopaneForecastURL = zakopaneForecastQuery + "&timezone=Europe/Warsaw&forecast_days=8"
    private static let zakopaneAutoForecastURL = zakopaneForecastQuery + "&timezone=auto&forecast_days=8"
    private static let zakopaneConditions: [WeatherCondition] = [.clear, .cloudy, .drizzle, .drizzle, .drizzle, .drizzle, .drizzle]
    private static let zakopaneHighs = [13.1, 12.0, 5.2, 9.6, 14.4, 11.6, 8.8]
    private static let zakopanePrecipitationProbabilities = [0.0, 0.04, 0.07, 0.2, 0.43, 0.67, 0.44]
    private static let zakopaneWithoutTimeZone = City(
        id: 3_080_866, name: "Zakopane", region: "Lesser Poland", country: "Poland", countryCode: "PL",
        latitude: 49.2992, longitude: 19.9496, timeZoneIdentifier: nil
    )

    private let sleeper = RecordingSleeper()

    @Test("Searching for Lisbon sends the expected URL once and returns the mapped cities in API order")
    func lisbonSearch() async throws {
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(try Fixtures.response(.geocodingLisbon))])
        let cities = try await geocoder(transport: transport).cities(named: "Lisbon")

        #expect(cities == Fixtures.geocodedLisbonCities)
        let requests = await transport.requests
        #expect(requests.map { $0.url?.absoluteString } == [Self.lisbonSearchURL])
        #expect(requests.first?.httpMethod == "GET")
        #expect(await sleeper.durations.isEmpty)
    }

    @Test("A name with diacritics and a space is percent-encoded on the wire")
    func encodedSearch() async throws {
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(try Fixtures.response(.geocodingSaoPaulo))])
        let cities = try await geocoder(transport: transport).cities(named: "São Paulo")

        #expect(cities.count == 10)
        #expect(cities.first?.name == "São Paulo")
        #expect(await transport.requests.map { $0.url?.absoluteString } == [Self.saoPauloSearchURL])
    }

    @Test("The Zakopane forecast asks for one extra day and returns seven mapped days at local midnight")
    func zakopaneForecast() async throws {
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(try Fixtures.response(.forecastZakopane))])
        let days = try await forecaster(transport: transport).dailyWeather(for: Fixtures.zakopane, dayCount: 7)

        let midnights = try (17...23).map { try Fixtures.localMidnight(2026, 10, $0, in: "Europe/Warsaw") }
        #expect(days.count == 7)
        #expect(days.map(\.date) == midnights)
        #expect(days.first?.date == Date(timeIntervalSince1970: 1_792_188_000))
        #expect(days.map(\.condition) == Self.zakopaneConditions)
        #expect(days.map(\.highCelsius) == Self.zakopaneHighs)
        let probabilities = days.map { $0.precipitationProbability ?? .nan }
        #expect(probabilities.count == Self.zakopanePrecipitationProbabilities.count)
        #expect(zip(probabilities, Self.zakopanePrecipitationProbabilities).allSatisfy { abs($0 - $1) < 1e-9 })
        #expect(await transport.requests.map { $0.url?.absoluteString } == [Self.zakopaneForecastURL])
        #expect(await sleeper.durations.isEmpty)
    }

    @Test("A city without a time zone asks for the automatic zone and its days follow the zone the response reports")
    func automaticTimeZoneForecast() async throws {
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(try Fixtures.response(.forecastZakopaneAuto))])
        let days = try await forecaster(transport: transport).dailyWeather(for: Self.zakopaneWithoutTimeZone, dayCount: 7)

        let midnights = try (17...23).map { try Fixtures.localMidnight(2026, 10, $0, in: "Europe/Warsaw") }
        #expect(days.map(\.date) == midnights)
        #expect(days.map(\.condition) == Self.zakopaneConditions)
        #expect(await transport.requests.map { $0.url?.absoluteString } == [Self.zakopaneAutoForecastURL])
    }

    @Test("An overloaded 503 is retried once after half a second and then succeeds")
    func overloadedThenSuccess() async throws {
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [
            .success(try Fixtures.response(.forecastErrorOverloaded, status: 503)),
            .success(try Fixtures.response(.forecastZakopane)),
        ])
        let days = try await forecaster(transport: transport).dailyWeather(for: Fixtures.zakopane, dayCount: 7)

        #expect(days.count == 7)
        let requests = await transport.requests
        #expect(requests.count == 2)
        #expect(requests.map { $0.url?.absoluteString } == [Self.zakopaneForecastURL, Self.zakopaneForecastURL])
        #expect(await sleeper.durations == [.milliseconds(500)])
    }

    @Test("Three overloaded 503s use up both retries and fail with the last status")
    func overloadedThrice() async throws {
        let overloaded = try Fixtures.response(.forecastErrorOverloaded, status: 503)
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(overloaded), .success(overloaded), .success(overloaded)])
        let error = await #expect(throws: NetworkError.self) {
            try await forecaster(transport: transport).dailyWeather(for: Fixtures.zakopane, dayCount: 7)
        }

        #expect(Fixtures.statusResponse(of: error)?.statusCode == 503)
        #expect(Fixtures.statusResponse(of: error)?.body == overloaded.body)
        #expect(await transport.requests.count == 3)
        #expect(await sleeper.durations == [.milliseconds(500), .seconds(1)])
    }

    @Test("A 400 bad forecast request fails at once without a retry")
    func badRequest() async throws {
        let rejected = try Fixtures.response(.forecastErrorBadDailyVariable, status: 400)
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(rejected)])
        let error = await #expect(throws: NetworkError.self) {
            try await forecaster(transport: transport).dailyWeather(for: Fixtures.zakopane, dayCount: 7)
        }

        #expect(Fixtures.statusResponse(of: error)?.statusCode == 400)
        #expect(Fixtures.statusResponse(of: error)?.body == rejected.body)
        #expect(await transport.requests.count == 1)
        #expect(await sleeper.durations.isEmpty)
    }

    @Test("A rejected search fails at once without a retry")
    func rejectedSearch() async throws {
        let rejected = try Fixtures.response(.geocodingErrorCountZero, status: 400)
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(rejected)])
        let error = await #expect(throws: NetworkError.self) {
            try await geocoder(transport: transport).cities(named: "Lisbon")
        }

        #expect(Fixtures.statusResponse(of: error)?.statusCode == 400)
        #expect(Fixtures.statusResponse(of: error)?.body == rejected.body)
        #expect(await transport.requests.count == 1)
        #expect(await sleeper.durations.isEmpty)
    }

    @Test("Being offline fails at once without a retry and reads as a connectivity error")
    func offline() async {
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.failure(NetworkError.transport(URLError(.notConnectedToInternet)))])
        let error = await #expect(throws: NetworkError.self) {
            try await forecaster(transport: transport).dailyWeather(for: Fixtures.zakopane, dayCount: 7)
        }

        #expect(Fixtures.urlErrorCode(of: error) == .notConnectedToInternet)
        #expect(error?.isConnectivity == true)
        #expect(await transport.requests.count == 1)
        #expect(await sleeper.durations.isEmpty)
    }

    @Test("A dropped connection is retried once after half a second and then succeeds")
    func connectionLostThenSuccess() async throws {
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [
            .failure(NetworkError.transport(URLError(.networkConnectionLost))),
            .success(try Fixtures.response(.forecastZakopane)),
        ])
        let days = try await forecaster(transport: transport).dailyWeather(for: Fixtures.zakopane, dayCount: 7)

        #expect(days.count == 7)
        #expect(await transport.requests.count == 2)
        #expect(await sleeper.durations == [.milliseconds(500)])
    }

    @Test("A successful response whose body is not a forecast fails with a decoding error without a retry", arguments: [
        Fixtures.File.geocodingLisbon,
        Fixtures.File.forecastErrorOverloaded,
    ])
    func notAForecast(file: Fixtures.File) async throws {
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(try Fixtures.response(file, status: 200))])
        let error = await #expect(throws: NetworkError.self) {
            try await forecaster(transport: transport).dailyWeather(for: Fixtures.zakopane, dayCount: 7)
        }

        #expect(Self.isDecoding(error))
        #expect(await transport.requests.count == 1)
        #expect(await sleeper.durations.isEmpty)
    }

    @Test("A successful response with a truncated body fails with a decoding error without a retry")
    func truncatedBody() async throws {
        let complete = try Fixtures.response(.forecastZakopane)
        let truncated = HTTPResponse(statusCode: 200, headers: complete.headers, body: Data(complete.body.prefix(complete.body.count / 2)), url: nil)
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(truncated)])
        let error = await #expect(throws: NetworkError.self) {
            try await forecaster(transport: transport).dailyWeather(for: Fixtures.zakopane, dayCount: 7)
        }

        #expect(Self.isDecoding(error))
        #expect(await transport.requests.count == 1)
        #expect(await sleeper.durations.isEmpty)
    }

    private func geocoder(transport: MockHTTPTransport) throws -> OpenMeteoGeocoder {
        OpenMeteoGeocoder(
            client: try Fixtures.client(host: OpenMeteoStandard.geocodingHost, transport: transport, sleeper: sleeper),
            requests: Fixtures.geocodingRequests(),
            mapper: Fixtures.cityMapper()
        )
    }

    private func forecaster(transport: MockHTTPTransport) throws -> OpenMeteoWeatherForecaster {
        OpenMeteoWeatherForecaster(
            client: try Fixtures.client(host: OpenMeteoStandard.forecastHost, transport: transport, sleeper: sleeper),
            requests: Fixtures.forecastRequests(),
            mapper: Fixtures.dailyWeatherMapper()
        )
    }

    private static func isDecoding(_ error: NetworkError?) -> Bool {
        guard case .decoding? = error else { return false }
        return true
    }
}
