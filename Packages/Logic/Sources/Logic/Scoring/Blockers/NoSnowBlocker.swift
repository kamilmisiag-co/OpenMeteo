//
//  NoSnowBlocker.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct NoSnowBlocker: BlockingRule {
    private let minimumDepthCm: Double
    private let minimumSnowfallCm: Double

    public init(minimumDepthCm: Double, minimumSnowfallCm: Double) {
        self.minimumDepthCm = minimumDepthCm
        self.minimumSnowfallCm = minimumSnowfallCm
    }

    public var kind: Factor.Kind { .snowfall }

    public func blocks(day index: Int, in days: [DailyWeather]) -> Bool {
        guard let day = days.element(at: index), (day.snowDepthCm ?? 0) < minimumDepthCm else { return false }
        return days[...index].sum(of: \.snowfallCm) < minimumSnowfallCm
    }
}
