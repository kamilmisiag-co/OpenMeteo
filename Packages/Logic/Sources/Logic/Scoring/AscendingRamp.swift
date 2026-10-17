//
//  AscendingRamp.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct AscendingRamp: SuitabilityCurve {
    private let zeroUntil: Double
    private let fullFrom: Double

    public init(zeroUntil: Double, fullFrom: Double) {
        self.zeroUntil = zeroUntil
        self.fullFrom = fullFrom
    }

    public func suitability(of value: Double) -> Double {
        guard value > zeroUntil else { return 0 }
        guard fullFrom > zeroUntil else { return 1 }
        let level = 1 - (fullFrom - value) / (fullFrom - zeroUntil)
        return level.isNaN ? 0 : level.clamped(to: 0...1)
    }
}
