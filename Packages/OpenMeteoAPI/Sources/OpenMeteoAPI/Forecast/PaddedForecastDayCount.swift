//
//  PaddedForecastDayCount.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol ForecastDayCounting: Sendable {
    func requestedDays(forUpcomingDays dayCount: Int) -> Int
}

public struct PaddedForecastDayCount: ForecastDayCounting {
    private let additionalDays: Int
    private let maximumDays: Int

    public init(additionalDays: Int, maximumDays: Int) {
        self.additionalDays = additionalDays
        self.maximumDays = maximumDays
    }

    public func requestedDays(forUpcomingDays dayCount: Int) -> Int {
        min(dayCount + additionalDays, maximumDays)
    }
}
