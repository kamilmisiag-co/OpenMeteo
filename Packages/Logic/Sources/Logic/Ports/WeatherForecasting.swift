//
//  WeatherForecasting.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol WeatherForecasting: Sendable {
    func dailyWeather(for city: City, dayCount: Int) async throws -> [DailyWeather]
}
