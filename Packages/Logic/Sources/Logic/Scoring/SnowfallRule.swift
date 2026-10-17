//
//  SnowfallRule.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct SnowfallRule: FactorRule {
    public let weight: Double
    private let snowfallCurve: any SuitabilityCurve

    public init(weight: Double, snowfallCurve: any SuitabilityCurve) {
        self.weight = weight
        self.snowfallCurve = snowfallCurve
    }

    public var kind: Factor.Kind { .snowfall }

    public func suitability(ofDay index: Int, in days: [DailyWeather]) -> Double? {
        guard days.indices.contains(index) else { return nil }
        return snowfallCurve.suitability(of: days[index].snowfallCm).clamped(to: 0...1)
    }
}
