//
//  ForecastRequestFactory.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic

public protocol ForecastRequestMaking: Sendable {
    func request(for city: City, upcomingDays dayCount: Int) -> ForecastEndpoint
}

public struct ForecastRequestFactory: ForecastRequestMaking {
    private let dayCounts: any ForecastDayCounting
    private let fallbackTimeZoneIdentifier: String

    public init(dayCounts: any ForecastDayCounting, fallbackTimeZoneIdentifier: String) {
        self.dayCounts = dayCounts
        self.fallbackTimeZoneIdentifier = fallbackTimeZoneIdentifier
    }

    public func request(for city: City, upcomingDays dayCount: Int) -> ForecastEndpoint {
        ForecastEndpoint(
            latitude: city.latitude,
            longitude: city.longitude,
            timeZoneIdentifier: city.timeZone?.identifier ?? fallbackTimeZoneIdentifier,
            dayCount: dayCounts.requestedDays(forUpcomingDays: dayCount)
        )
    }
}
