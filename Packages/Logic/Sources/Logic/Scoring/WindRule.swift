//
//  WindRule.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct WindRule: FactorRule {
    public let weight: Double
    private let speedCurve: any SuitabilityCurve
    private let gustCurve: any SuitabilityCurve

    public init(weight: Double, speedCurve: any SuitabilityCurve, gustCurve: any SuitabilityCurve) {
        self.weight = weight
        self.speedCurve = speedCurve
        self.gustCurve = gustCurve
    }

    public var kind: Factor.Kind { .wind }

    public func suitability(ofDay index: Int, in days: [DailyWeather]) -> Double? {
        guard let day = days.element(at: index) else { return nil }
        return min(speedCurve.suitability(of: day.windSpeedKmh), gustCurve.suitability(of: day.windGustsKmh)).clamped(to: 0...1)
    }
}
