//
//  OpenMeteoWeatherForecaster.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Networking

public struct OpenMeteoWeatherForecaster: WeatherForecasting {
    private let client: any HTTPClient
    private let requests: any ForecastRequestMaking
    private let mapper: any DailyWeatherMapping

    public init(client: any HTTPClient, requests: any ForecastRequestMaking, mapper: any DailyWeatherMapping) {
        self.client = client
        self.requests = requests
        self.mapper = mapper
    }

    public func dailyWeather(for city: City, dayCount: Int) async throws -> [DailyWeather] {
        mapper.dailyWeather(from: try await client.send(requests.request(for: city, upcomingDays: dayCount)))
    }
}
