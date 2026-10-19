//
//  ComfortBand.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct ComfortBand: SuitabilityCurve {
    private let ideal: ClosedRange<Double>
    private let zeroBelow: Double
    private let zeroAbove: Double

    public init(ideal: ClosedRange<Double>, zeroBelow: Double, zeroAbove: Double) {
        self.ideal = ideal
        self.zeroBelow = zeroBelow
        self.zeroAbove = zeroAbove
    }

    public func suitability(of value: Double) -> Double {
        if ideal.contains(value) { return 1 }
        return if value < ideal.lowerBound {
            falloff(ideal.lowerBound - value, over: ideal.lowerBound - zeroBelow)
        } else {
            falloff(value - ideal.upperBound, over: zeroAbove - ideal.upperBound)
        }
    }

    private func falloff(_ distance: Double, over span: Double) -> Double {
        guard span > 0 else { return 0 }
        let level = 1 - distance / span
        return level.clamped(to: 0...1, ifNaN: 0)
    }
}
