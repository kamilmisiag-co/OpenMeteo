//
//  HourlySnowDepthAggregator.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public protocol SnowDepthAggregating: Sendable {
    func dailyMaximumSnowDepth(in hourly: ForecastResponseDTO.Hourly, dayKeys: any DayKeyExtracting) -> [String: Double]
}

public struct HourlySnowDepthAggregator: SnowDepthAggregating {
    public init() {}

    public func dailyMaximumSnowDepth(in hourly: ForecastResponseDTO.Hourly, dayKeys: any DayKeyExtracting) -> [String: Double] {
        var depths: [String: Double] = [:]
        for (time, value) in zip(hourly.time, hourly.snowDepth) {
            guard let depth = value?.finiteValue else { continue }
            let dayKey = dayKeys.dayKey(of: time)
            depths[dayKey] = max(depths[dayKey] ?? depth, depth)
        }
        return depths
    }
}
