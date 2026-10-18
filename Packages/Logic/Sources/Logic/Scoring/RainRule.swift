//
//  RainRule.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct RainRule: FactorRule {
    public let weight: Double
    private let probabilityCurve: any SuitabilityCurve
    private let minimumHighCelsius: Double?

    public init(weight: Double, probabilityCurve: any SuitabilityCurve, minimumHighCelsius: Double?) {
        self.weight = weight
        self.probabilityCurve = probabilityCurve
        self.minimumHighCelsius = minimumHighCelsius
    }

    public var kind: Factor.Kind { .rain }

    public func suitability(ofDay index: Int, in days: [DailyWeather]) -> Double? {
        guard let day = days.element(at: index), let probability = day.precipitationProbability else { return nil }
        if let minimumHighCelsius, day.highCelsius <= minimumHighCelsius { return 1 }
        return probabilityCurve.suitability(of: probability.clamped(to: 0...1)).clamped(to: 0...1)
    }
}
