//
//  FloatingPoint+Fraction.swift
//  Utils
//
//  Created by Kamil Misiag on 19/10/2026.
//

extension FloatingPoint {
    public func fraction(of range: ClosedRange<Self>) -> Self {
        let fraction = (self - range.lowerBound) / (range.upperBound - range.lowerBound)
        return fraction.clamped(to: 0...1, ifNaN: 0)
    }
}
