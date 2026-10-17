//
//  SnowDepthAggregating.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol SnowDepthAggregating: Sendable {
    func dailyMaximumSnowDepth(in hourly: ForecastResponseDTO.Hourly, dayKeys: any DayKeyExtracting) -> [String: Double]
}
