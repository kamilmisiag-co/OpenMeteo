//
//  DescendingRamp.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct DescendingRamp: SuitabilityCurve {
    private let fullUntil: Double
    private let zeroFrom: Double

    public init(fullUntil: Double, zeroFrom: Double) {
        self.fullUntil = fullUntil
        self.zeroFrom = zeroFrom
    }

    public func suitability(of value: Double) -> Double {
        if value <= fullUntil { return 1 }
        guard zeroFrom > fullUntil else { return 0 }
        let level = 1 - (value - fullUntil) / (zeroFrom - fullUntil)
        return level.isNaN ? 0 : level.clamped(to: 0...1)
    }
}
