//
//  MockWeatherForecaster.swift
//  LogicMocks
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic

public actor MockWeatherForecaster: WeatherForecasting {
    public struct Request: Hashable, Sendable {
        public let city: City
        public let dayCount: Int

        public init(city: City, dayCount: Int) {
            self.city = city
            self.dayCount = dayCount
        }
    }

    public typealias Handler = @Sendable (City, Int) async throws -> [DailyWeather]

    private let handler: Handler
    public private(set) var requests: [Request] = []

    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    public func dailyWeather(for city: City, dayCount: Int) async throws -> [DailyWeather] {
        requests.append(Request(city: city, dayCount: dayCount))
        return try await handler(city, dayCount)
    }
}
