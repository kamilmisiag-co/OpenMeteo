//
//  FloatingPoint+Clamped.swift
//  Utils
//
//  Created by Kamil Misiag on 18/10/2026.
//

extension FloatingPoint {
    public func clamped(to range: ClosedRange<Self>, ifNaN fallback: Self) -> Self {
        guard isNaN else { return clamped(to: range) }
        return fallback.isNaN ? range.lowerBound : fallback.clamped(to: range)
    }
}
