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
        guard let day = days.element(at: index) else { return nil }
        return snowfallCurve.suitability(of: day.snowfallCm)
    }
}
