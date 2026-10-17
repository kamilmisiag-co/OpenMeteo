//
//  EffectThresholds.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct EffectThresholds: Hashable, Sendable {
    public let helpsFrom: Double
    public let hurtsBelow: Double

    public init(helpsFrom: Double, hurtsBelow: Double) {
        self.helpsFrom = helpsFrom
        self.hurtsBelow = hurtsBelow
    }
}
