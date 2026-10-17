//
//  ForecastDayCounting.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol ForecastDayCounting: Sendable {
    func requestedDays(forUpcomingDays dayCount: Int) -> Int
}
