//
//  PaddedForecastDayCount.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct PaddedForecastDayCount: ForecastDayCounting {
    private let additionalDays: Int
    private let maximumDays: Int

    public init(additionalDays: Int, maximumDays: Int) {
        self.maximumDays = max(maximumDays, 1)
        self.additionalDays = additionalDays.clamped(to: 0...self.maximumDays)
    }

    public func requestedDays(forUpcomingDays dayCount: Int) -> Int {
        max(dayCount.clamped(to: 0...(maximumDays - additionalDays)) + additionalDays, 1)
    }
}
