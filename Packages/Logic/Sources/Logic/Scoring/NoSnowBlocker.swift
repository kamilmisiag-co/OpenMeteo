//
//  NoSnowBlocker.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct NoSnowBlocker: BlockingRule {
    private let minimumDepthCm: Double
    private let minimumSnowfallCm: Double

    public init(minimumDepthCm: Double, minimumSnowfallCm: Double) {
        self.minimumDepthCm = minimumDepthCm
        self.minimumSnowfallCm = minimumSnowfallCm
    }

    public var kind: Factor.Kind { .snowfall }

    public func blocks(day index: Int, in days: [DailyWeather]) -> Bool {
        guard days.indices.contains(index), (days[index].snowDepthCm ?? 0) < minimumDepthCm else { return false }
        return days[...index].reduce(0) { $0 + $1.snowfallCm } < minimumSnowfallCm
    }
}
