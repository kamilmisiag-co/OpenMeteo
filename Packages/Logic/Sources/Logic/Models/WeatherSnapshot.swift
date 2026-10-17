//
//  WeatherSnapshot.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation

public struct WeatherSnapshot: Hashable, Codable, Sendable {
    public let city: City
    public let days: [DailyWeather]
    public let fetchedAt: Date

    public init(city: City, days: [DailyWeather], fetchedAt: Date) {
        self.city = city
        self.days = days
        self.fetchedAt = fetchedAt
    }
}
