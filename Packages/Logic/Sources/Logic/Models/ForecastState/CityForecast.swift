//
//  CityForecast.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation

public struct CityForecast: Hashable, Sendable {
    public let city: City
    public let days: [DailyWeather]
    public let outlooks: [ActivityOutlook]
    public let fetchedAt: Date

    public init(city: City, days: [DailyWeather], outlooks: [ActivityOutlook], fetchedAt: Date) {
        self.city = city
        self.days = days
        self.outlooks = outlooks
        self.fetchedAt = fetchedAt
    }
}
