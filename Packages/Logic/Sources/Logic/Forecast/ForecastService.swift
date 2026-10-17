//
//  ForecastService.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation

public struct ForecastService: ForecastProviding {
    private let weather: any WeatherForecasting
    private let cache: any WeatherCaching
    private let window: any DayWindowing
    private let outlookBuilder: any OutlookBuilding
    private let fallbackPolicy: any CacheFallbackPolicy
    private let dateProvider: any DateProviding

    public init(
        weather: any WeatherForecasting,
        cache: any WeatherCaching,
        window: any DayWindowing,
        outlookBuilder: any OutlookBuilding,
        fallbackPolicy: any CacheFallbackPolicy,
        dateProvider: any DateProviding
    ) {
        self.weather = weather
        self.cache = cache
        self.window = window
        self.outlookBuilder = outlookBuilder
        self.fallbackPolicy = fallbackPolicy
        self.dateProvider = dateProvider
    }

    public func forecast(for city: City) async throws -> ForecastResult {
        let result: ForecastResult
        do {
            result = try await loadForecast(for: city)
        } catch {
            try Task.checkCancellation()
            throw error
        }
        try Task.checkCancellation()
        return result
    }

    private func loadForecast(for city: City) async throws -> ForecastResult {
        let fetchedDays: [DailyWeather]
        do {
            fetchedDays = try await weather.dailyWeather(for: city, dayCount: window.dayCount)
        } catch {
            try Task.checkCancellation()
            guard let cached = await cachedForecast(for: city, after: error) else { throw error }
            return ForecastResult(forecast: cached, origin: .cache)
        }
        let now = dateProvider.now()
        let snapshot = WeatherSnapshot(city: city, days: fetchedDays, fetchedAt: now)
        guard let live = cityForecast(from: snapshot, for: city, at: now) else { throw ForecastError.noUpcomingDays }
        await cache.store(snapshot)
        return ForecastResult(forecast: live, origin: .live)
    }

    private func cachedForecast(for city: City, after error: any Error) async -> CityForecast? {
        guard fallbackPolicy.allowsCachedForecast(after: error),
              let snapshot = await cache.snapshot(for: city) else { return nil }
        return cityForecast(from: snapshot, for: city, at: dateProvider.now())
    }

    private func cityForecast(from snapshot: WeatherSnapshot, for city: City, at now: Date) -> CityForecast? {
        let days = window.upcomingDays(snapshot.days, in: city, now: now)
        guard !days.isEmpty else { return nil }
        return CityForecast(city: city, days: days, outlooks: outlookBuilder.outlooks(for: days), fetchedAt: snapshot.fetchedAt)
    }
}
