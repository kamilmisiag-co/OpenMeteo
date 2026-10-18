//
//  TemperatureRule.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct TemperatureRule: FactorRule {
    public let weight: Double
    private let highCurve: any SuitabilityCurve

    public init(weight: Double, highCurve: any SuitabilityCurve) {
        self.weight = weight
        self.highCurve = highCurve
    }

    public var kind: Factor.Kind { .temperature }

    public func suitability(ofDay index: Int, in days: [DailyWeather]) -> Double? {
        guard let day = days.element(at: index) else { return nil }
        return highCurve.suitability(of: day.highCelsius).clamped(to: 0...1)
    }
}
