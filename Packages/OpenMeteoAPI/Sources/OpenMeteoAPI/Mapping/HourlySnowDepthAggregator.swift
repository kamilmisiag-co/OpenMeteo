//
//  HourlySnowDepthAggregator.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct HourlySnowDepthAggregator: SnowDepthAggregating {
    public init() {}

    public func dailyMaximumSnowDepth(in hourly: ForecastResponseDTO.Hourly, dayKeys: any DayKeyExtracting) -> [String: Double] {
        var depths: [String: Double] = [:]
        for (time, value) in zip(hourly.time, hourly.snowDepth) {
            guard let depth = value, depth.isFinite else { continue }
            let dayKey = dayKeys.dayKey(of: time)
            depths[dayKey] = max(depths[dayKey] ?? depth, depth)
        }
        return depths
    }
}
