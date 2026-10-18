//
//  ForecastServiceTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import LogicMocks
import Synchronization
import Testing
import UtilsMocks

@Suite("Forecast service")
struct ForecastServiceTests {
    private enum ServiceError: Error {
        case unavailable
    }

    private final class RecordingOutlookBuilder: OutlookBuilding {
        private let received = Mutex<[[DailyWeather]]>([])

        var receivedDays: [[DailyWeather]] {
            received.withLock { $0 }
        }

        func outlooks(for days: [DailyWeather]) -> [ActivityOutlook] {
            received.withLock { $0.append(days) }
            return Self.outlooks(for: days)
        }

        static func outlooks(for days: [DailyWeather]) -> [ActivityOutlook] {
            [ActivityOutlook(activity: .surfing, days: days.map { DayAssessment(score: Int($0.highCelsius), effects: [:]) }, factors: [])]
        }
    }

    private struct FixedFallbackPolicy: CacheFallbackPolicy {
        let allows: Bool

        func allowsCachedForecast(after error: any Error) -> Bool {
            allows
        }
    }

    private static let dayCount = 5
    private static let cachedAt = Fixtures.referenceNow.addingTimeInterval(-2 * 60 * 60)
    private static let cachedSnapshot = WeatherSnapshot(city: Fixtures.lisbon, days: Fixtures.lisbonDays(from: 15, count: 7), fetchedAt: cachedAt)
    private let dateProvider = ManualDateProvider(now: Fixtures.referenceNow)
    private let outlookBuilder = RecordingOutlookBuilder()

    @Test("A live forecast asks for the window's day count, keeps the upcoming days and stores the raw response")
    func liveForecast() async throws {
        let weather = MockWeatherForecaster { _, dayCount in Fixtures.lisbonDays(from: 16, count: dayCount + 1) }
        let cache = InMemoryWeatherCache(snapshots: [])
        let result = try await service(weather: weather, cache: cache).forecast(for: Fixtures.lisbon)

        let fetched = Fixtures.lisbonDays(from: 16, count: Self.dayCount + 1)
        let upcoming = Array(fetched.dropFirst())
        let expected = CityForecast(
            city: Fixtures.lisbon, days: upcoming, outlooks: RecordingOutlookBuilder.outlooks(for: upcoming), fetchedAt: Fixtures.referenceNow
        )
        #expect(result == ForecastResult(forecast: expected, origin: .live))
        #expect(await weather.requests == [MockWeatherForecaster.Request(city: Fixtures.lisbon, dayCount: Self.dayCount)])
        #expect(await cache.storedSnapshots == [WeatherSnapshot(city: Fixtures.lisbon, days: fetched, fetchedAt: Fixtures.referenceNow)])
        #expect(outlookBuilder.receivedDays == [upcoming])
    }

    @Test("Every live fetch is stamped with the current time and replaces the cached snapshot")
    func liveTimestamps() async throws {
        let days = Fixtures.lisbonDays(from: 17, count: Self.dayCount)
        let weather = MockWeatherForecaster { _, _ in days }
        let cache = InMemoryWeatherCache(snapshots: [Self.cachedSnapshot])
        let forecaster = service(weather: weather, cache: cache)
        let first = try await forecaster.forecast(for: Fixtures.lisbon)
        dateProvider.advance(by: .seconds(90))
        let second = try await forecaster.forecast(for: Fixtures.lisbon)

        let later = Fixtures.referenceNow.addingTimeInterval(90)
        #expect([first.origin, second.origin] == [.live, .live])
        #expect([first.forecast.fetchedAt, second.forecast.fetchedAt] == [Fixtures.referenceNow, later])
        #expect(await cache.storedSnapshots.map(\.fetchedAt) == [Fixtures.referenceNow, later])
        #expect(await cache.snapshot(for: Fixtures.lisbon) == WeatherSnapshot(city: Fixtures.lisbon, days: days, fetchedAt: later))
    }

    @Test("A connectivity failure falls back to the cached snapshot's upcoming days for the requested city")
    func cachedFallback() async throws {
        let cachedDays = Fixtures.lisbonDays(from: 15, count: 7)
        let cache = InMemoryWeatherCache(snapshots: [WeatherSnapshot(city: Fixtures.lisboa, days: cachedDays, fetchedAt: Self.cachedAt)])
        let weather = MockWeatherForecaster { _, _ in throw URLError(.notConnectedToInternet) }
        let result = try await service(weather: weather, cache: cache).forecast(for: Fixtures.lisbon)

        let upcoming = Array(cachedDays.dropFirst(2))
        let expected = CityForecast(
            city: Fixtures.lisbon, days: upcoming, outlooks: RecordingOutlookBuilder.outlooks(for: upcoming), fetchedAt: Self.cachedAt
        )
        #expect(result == ForecastResult(forecast: expected, origin: .cache))
        #expect(outlookBuilder.receivedDays == [upcoming])
        #expect(await weather.requests == [MockWeatherForecaster.Request(city: Fixtures.lisbon, dayCount: Self.dayCount)])
        #expect(await cache.storedSnapshots.isEmpty)
    }

    @Test("Cached days are windowed against the time of the fallback")
    func cachedFallbackLater() async throws {
        let cache = InMemoryWeatherCache(snapshots: [Self.cachedSnapshot])
        let weather = MockWeatherForecaster { _, _ in throw URLError(.networkConnectionLost) }
        dateProvider.set(Fixtures.date(2026, 10, 20, hour: 12, in: "Europe/Lisbon"))
        let result = try await service(weather: weather, cache: cache).forecast(for: Fixtures.lisbon)

        #expect(result.origin == .cache)
        #expect(result.forecast.days == Array(Self.cachedSnapshot.days.suffix(2)))
        #expect(result.forecast.fetchedAt == Self.cachedAt)
    }

    @Test("A connectivity failure without a cached snapshot for the city throws the original error")
    func connectivityFailureWithoutCache() async {
        let otherCity = WeatherSnapshot(city: Fixtures.bergen, days: Fixtures.lisbonDays(from: 17, count: 5), fetchedAt: Self.cachedAt)
        let cache = InMemoryWeatherCache(snapshots: [otherCity])
        let weather = MockWeatherForecaster { _, _ in throw URLError(.timedOut) }
        await #expect(throws: URLError(.timedOut)) {
            try await service(weather: weather, cache: cache).forecast(for: Fixtures.lisbon)
        }
        #expect(outlookBuilder.receivedDays.isEmpty)
        #expect(await cache.storedSnapshots.isEmpty)
    }

    @Test("Errors that aren't connectivity failures skip the cache and propagate unchanged")
    func nonConnectivityError() async {
        let cache = InMemoryWeatherCache(snapshots: [Self.cachedSnapshot])
        let failing = MockWeatherForecaster { _, _ in throw ServiceError.unavailable }
        await #expect(throws: ServiceError.unavailable) {
            try await service(weather: failing, cache: cache).forecast(for: Fixtures.lisbon)
        }
        let badResponse = MockWeatherForecaster { _, _ in throw URLError(.badServerResponse) }
        await #expect(throws: URLError(.badServerResponse)) {
            try await service(weather: badResponse, cache: cache).forecast(for: Fixtures.lisbon)
        }
        #expect(outlookBuilder.receivedDays.isEmpty)
        #expect(await cache.storedSnapshots.isEmpty)
    }

    @Test("A cancelled request never falls back to the cache")
    func cancellation() async {
        let cache = InMemoryWeatherCache(snapshots: [Self.cachedSnapshot])
        let cancelled = MockWeatherForecaster { _, _ in throw CancellationError() }
        await #expect(throws: CancellationError.self) {
            try await service(weather: cancelled, cache: cache).forecast(for: Fixtures.lisbon)
        }
        let cancelledRequest = MockWeatherForecaster { _, _ in throw URLError(.cancelled) }
        await #expect(throws: URLError(.cancelled)) {
            try await service(weather: cancelledRequest, cache: cache).forecast(for: Fixtures.lisbon)
        }
        #expect(outlookBuilder.receivedDays.isEmpty)
    }

    @Test("A cached snapshot with no upcoming days is ignored and the original error is thrown")
    func outdatedCache() async {
        let outdated = WeatherSnapshot(city: Fixtures.lisbon, days: Fixtures.lisbonDays(from: 10, count: 7), fetchedAt: Self.cachedAt)
        let cache = InMemoryWeatherCache(snapshots: [outdated])
        let weather = MockWeatherForecaster { _, _ in throw URLError(.notConnectedToInternet) }
        await #expect(throws: URLError(.notConnectedToInternet)) {
            try await service(weather: weather, cache: cache).forecast(for: Fixtures.lisbon)
        }
    }

    @Test("Live data with no upcoming days throws without storing it or falling back to the cache")
    func noUpcomingDays() async {
        let cache = InMemoryWeatherCache(snapshots: [Self.cachedSnapshot])
        let past = MockWeatherForecaster { _, _ in Fixtures.lisbonDays(from: 10, count: 7) }
        await #expect(throws: ForecastError.noUpcomingDays) {
            try await service(weather: past, cache: cache).forecast(for: Fixtures.lisbon)
        }
        let empty = MockWeatherForecaster { _, _ in [] }
        await #expect(throws: ForecastError.noUpcomingDays) {
            try await service(weather: empty, cache: cache).forecast(for: Fixtures.lisbon)
        }
        #expect(await cache.storedSnapshots.isEmpty)
        #expect(await cache.snapshot(for: Fixtures.lisbon) == Self.cachedSnapshot)
    }

    @Test("The injected fallback policy decides whether the cache is used")
    func injectedPolicy() async throws {
        let cache = InMemoryWeatherCache(snapshots: [Self.cachedSnapshot])
        let failing = MockWeatherForecaster { _, _ in throw ServiceError.unavailable }
        let permissive = try await service(weather: failing, cache: cache, fallbackPolicy: FixedFallbackPolicy(allows: true))
            .forecast(for: Fixtures.lisbon)
        #expect(permissive.origin == .cache)
        #expect(permissive.forecast.fetchedAt == Self.cachedAt)

        let offline = MockWeatherForecaster { _, _ in throw URLError(.notConnectedToInternet) }
        await #expect(throws: URLError(.notConnectedToInternet)) {
            try await service(weather: offline, cache: cache, fallbackPolicy: FixedFallbackPolicy(allows: false)).forecast(for: Fixtures.lisbon)
        }
    }

    @Test("A forecast cancelled while the weather loads keeps the fresh data in the cache but is not returned")
    func cancelledAfterLoading() async {
        let weather = MockWeatherForecaster { _, dayCount in
            withUnsafeCurrentTask { $0?.cancel() }
            return Fixtures.lisbonDays(from: 17, count: dayCount)
        }
        let cache = InMemoryWeatherCache(snapshots: [])
        let forecasts = service(weather: weather, cache: cache)
        let task = Task { try await forecasts.forecast(for: Fixtures.lisbon) }
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(await cache.storedSnapshots.map(\.fetchedAt) == [Fixtures.referenceNow])
    }

    @Test("A forecast cancelled while offline does not fall back to the cache")
    func cancelledWhileOffline() async {
        let weather = MockWeatherForecaster { _, _ in
            withUnsafeCurrentTask { $0?.cancel() }
            throw URLError(.notConnectedToInternet)
        }
        let forecasts = service(weather: weather, cache: InMemoryWeatherCache(snapshots: [Self.cachedSnapshot]))
        let task = Task { try await forecasts.forecast(for: Fixtures.lisbon) }
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(outlookBuilder.receivedDays.isEmpty)
    }

    @Test("A forecast cancelled while loading past days reports the cancellation, not the missing days")
    func cancelledWithoutUpcomingDays() async {
        let weather = MockWeatherForecaster { _, _ in
            withUnsafeCurrentTask { $0?.cancel() }
            return Fixtures.lisbonDays(from: 10, count: 7)
        }
        let forecasts = service(weather: weather, cache: InMemoryWeatherCache(snapshots: []))
        let task = Task { try await forecasts.forecast(for: Fixtures.lisbon) }
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    private func service(
        weather: MockWeatherForecaster,
        cache: InMemoryWeatherCache,
        fallbackPolicy: any CacheFallbackPolicy = ConnectivityFallbackPolicy()
    ) -> ForecastService {
        ForecastService(
            weather: weather,
            cache: cache,
            window: UpcomingDaysWindow(dayCount: Self.dayCount, fallbackTimeZone: .gmt),
            outlookBuilder: outlookBuilder,
            fallbackPolicy: fallbackPolicy,
            dateProvider: dateProvider
        )
    }
}
