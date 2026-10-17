//
//  OpenMeteoWeatherForecasterTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import Networking
import NetworkingMocks
import OpenMeteoAPI
import Synchronization
import Testing
import Utils

@Suite("Open-Meteo weather forecaster")
struct OpenMeteoWeatherForecasterTests {
    private final class RecordingForecastRequests: ForecastRequestMaking {
        struct Call: Hashable, Sendable {
            let city: City
            let upcomingDays: Int
        }

        private let received = Mutex<[Call]>([])
        private let endpoint: ForecastEndpoint

        init(endpoint: ForecastEndpoint) {
            self.endpoint = endpoint
        }

        var calls: [Call] {
            received.withLock { $0 }
        }

        func request(for city: City, upcomingDays dayCount: Int) -> ForecastEndpoint {
            received.withLock { $0.append(Call(city: city, upcomingDays: dayCount)) }
            return endpoint
        }
    }

    private final class RecordingDailyWeatherMapper: DailyWeatherMapping {
        private let received = Mutex<[ForecastResponseDTO]>([])
        private let days: [DailyWeather]

        init(days: [DailyWeather]) {
            self.days = days
        }

        var receivedResponses: [ForecastResponseDTO] {
            received.withLock { $0 }
        }

        func dailyWeather(from response: ForecastResponseDTO) -> [DailyWeather] {
            received.withLock { $0.append(response) }
            return days
        }
    }

    private static let factoryEndpoint = ForecastEndpoint(
        latitude: -36.8485, longitude: 174.7633, timeZoneIdentifier: "Pacific/Auckland", dayCount: 3
    )

    private static let stubbedDays = [
        DailyWeather(
            date: Date(timeIntervalSince1970: 0), condition: .thunderstorm, highCelsius: 31, lowCelsius: 24, precipitationProbability: nil,
            windSpeedKmh: 3, windGustsKmh: 5, snowfallCm: 7, snowDepthCm: nil
        ),
        DailyWeather(
            date: Date(timeIntervalSince1970: 86_400), condition: .fog, highCelsius: -2, lowCelsius: -9, precipitationProbability: 0.5,
            windSpeedKmh: 11, windGustsKmh: 13, snowfallCm: 0, snowDepthCm: 17
        ),
    ]

    @Test(
        "The city and the day count reach the injected request factory unchanged",
        arguments: [(Fixtures.zakopane, 7), (Fixtures.noTimeZone, 0), (Fixtures.zakopane, -1), (Fixtures.noTimeZone, Int.max)]
    )
    func factoryInput(city: City, dayCount: Int) async throws {
        let requests = RecordingForecastRequests(endpoint: Self.factoryEndpoint)
        let client = try Self.client(returning: .forecastZakopane)
        _ = try await forecaster(client: client, requests: requests, mapper: RecordingDailyWeatherMapper(days: []))
            .dailyWeather(for: city, dayCount: dayCount)

        #expect(requests.calls == [RecordingForecastRequests.Call(city: city, upcomingDays: dayCount)])
    }

    @Test("The client sends exactly the request the injected factory made")
    func requestFromFactory() async throws {
        let client = try Self.client(returning: .forecastZakopane)
        _ = try await forecaster(client: client, mapper: RecordingDailyWeatherMapper(days: [])).dailyWeather(for: Fixtures.zakopane, dayCount: 7)

        let endpoints = await client.endpoints
        #expect(endpoints.count == 1)
        let sent = try #require(endpoints.first as? ForecastEndpoint)
        #expect(sent.latitude == Self.factoryEndpoint.latitude)
        #expect(sent.longitude == Self.factoryEndpoint.longitude)
        #expect(sent.timeZoneIdentifier == Self.factoryEndpoint.timeZoneIdentifier)
        #expect(sent.dayCount == Self.factoryEndpoint.dayCount)
        #expect(sent.queryItems == Self.factoryEndpoint.queryItems)
    }

    @Test("Each forecast asks the injected request factory for a new request")
    func requestPerForecast() async throws {
        let requests = RecordingForecastRequests(endpoint: Self.factoryEndpoint)
        let client = try Self.client(returning: .forecastZakopane)
        let subject = forecaster(client: client, requests: requests, mapper: RecordingDailyWeatherMapper(days: []))
        _ = try await subject.dailyWeather(for: Fixtures.zakopane, dayCount: 7)
        _ = try await subject.dailyWeather(for: Fixtures.noTimeZone, dayCount: 3)

        #expect(requests.calls == [
            RecordingForecastRequests.Call(city: Fixtures.zakopane, upcomingDays: 7),
            RecordingForecastRequests.Call(city: Fixtures.noTimeZone, upcomingDays: 3),
        ])
        #expect(await client.endpoints.count == 2)
    }

    @Test("The injected mapper receives the decoded response and its days are returned unchanged")
    func injectedMapper() async throws {
        let response = try Fixtures.decode(ForecastResponseDTO.self, from: .forecastZakopane)
        let client = MockHTTPClient { _ in response }
        let mapper = RecordingDailyWeatherMapper(days: Self.stubbedDays)
        let days = try await forecaster(client: client, mapper: mapper).dailyWeather(for: Fixtures.zakopane, dayCount: 7)

        #expect(days == Self.stubbedDays)
        #expect(mapper.receivedResponses == [response])
        #expect(await client.endpoints.count == 1)
    }

    @Test("A connectivity failure from the client reaches the caller unchanged")
    func connectivityFailure() async {
        let mapper = RecordingDailyWeatherMapper(days: Self.stubbedDays)
        let client = MockHTTPClient { _ in throw NetworkError.transport(URLError(.notConnectedToInternet)) }
        let error = await #expect(throws: NetworkError.self) {
            try await forecaster(client: client, mapper: mapper).dailyWeather(for: Fixtures.zakopane, dayCount: 7)
        }
        #expect(Fixtures.urlErrorCode(of: error) == .notConnectedToInternet)
        #expect(error?.isConnectivity == true)
        #expect(mapper.receivedResponses.isEmpty)
    }

    @Test("An unacceptable status from the client reaches the caller with the original response")
    func unacceptableStatus() async throws {
        let response = try Fixtures.response(.forecastErrorOverloaded, status: 503)
        let mapper = RecordingDailyWeatherMapper(days: Self.stubbedDays)
        let client = MockHTTPClient { _ in throw NetworkError.unacceptableStatusCode(response) }
        let error = await #expect(throws: NetworkError.self) {
            try await forecaster(client: client, mapper: mapper).dailyWeather(for: Fixtures.zakopane, dayCount: 7)
        }
        #expect(Fixtures.statusResponse(of: error) == response)
        #expect(mapper.receivedResponses.isEmpty)
    }

    @Test("Cancellation from the client is passed through as cancellation")
    func cancellation() async {
        let mapper = RecordingDailyWeatherMapper(days: Self.stubbedDays)
        let client = MockHTTPClient { _ in throw CancellationError() }
        await #expect(throws: CancellationError.self) {
            try await forecaster(client: client, mapper: mapper).dailyWeather(for: Fixtures.zakopane, dayCount: 7)
        }
        #expect(mapper.receivedResponses.isEmpty)
    }

    private func forecaster(
        client: any HTTPClient,
        requests: any ForecastRequestMaking = RecordingForecastRequests(endpoint: Self.factoryEndpoint),
        mapper: any DailyWeatherMapping
    ) -> OpenMeteoWeatherForecaster {
        OpenMeteoWeatherForecaster(client: client, requests: requests, mapper: mapper)
    }

    private static func client(returning file: Fixtures.File) throws -> MockHTTPClient {
        let response = try Fixtures.decode(ForecastResponseDTO.self, from: file)
        return MockHTTPClient { _ in response }
    }
}
